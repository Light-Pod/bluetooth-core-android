package dev.lightpod.bluetooth_core_android

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import java.io.IOException
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

// TODO: sink initial value?

class BluetoothCoreAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    ActivityResultListener, RequestPermissionsResultListener {
    private val namespace = "dev.lightpod.bluetooth_core_android"

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var executorService: ExecutorService? = null

    private var bluetoothStateEvent: EventChannel? = null
    private var bluetoothStateSink: EventSink? = null

    private var bluetoothDiscoveryEvent: EventChannel? = null
    private var bluetoothDiscoverySink: EventSink? = null

    private var deviceFoundEvent: EventChannel? = null
    private var deviceFoundSink: EventSink? = null

    private var bluetoothAdapter: BluetoothAdapter? = null

    private val permissionRequestManager = RequestManager<Result>()
    private val activityRequestManager =
        RequestManager<(requestCode: Int, resultCode: Int, data: Intent?) -> Boolean>()

    private val rfcommSockets = ConcurrentHashMap<String, BluetoothSocket>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, namespace)
        channel.setMethodCallHandler(this)

        val messenger = flutterPluginBinding.binaryMessenger
        val bluetoothManager =
            flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        executorService = Executors.newSingleThreadExecutor()

        initEvents(messenger)
    }

    private fun initEvents(messenger: BinaryMessenger) {
        bluetoothStateEvent = EventChannel(messenger, "$namespace/bluetooth_state_event")
        bluetoothStateEvent!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                bluetoothStateSink = events
            }

            override fun onCancel(arguments: Any?) {
                bluetoothStateSink = null
            }
        })

        bluetoothDiscoveryEvent = EventChannel(messenger, "$namespace/bluetooth_discovery_event")
        bluetoothDiscoveryEvent!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                bluetoothDiscoverySink = events
            }

            override fun onCancel(arguments: Any?) {
                bluetoothDiscoverySink = null
            }
        })

        deviceFoundEvent = EventChannel(messenger, "$namespace/found_device_event")
        deviceFoundEvent!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                deviceFoundSink = events
            }

            override fun onCancel(arguments: Any?) {
                deviceFoundSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activity?.unregisterReceiver(bluetoothBroadcastReceiver)
        bluetoothStateEvent?.setStreamHandler(null)
        deviceFoundEvent?.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        val filter = IntentFilter().apply {
            // Adapter Events
            // BluetoothAdapter.ACTION_REQUEST_ENABLE
            // BluetoothAdapter.ACTION_SCAN_MODE_CHANGED
            // BluetoothAdapter.ACTION_LOCAL_NAME_CHANGED
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)

            // Device Events
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothDevice.ACTION_NAME_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                addAction(BluetoothDevice.ACTION_ALIAS_CHANGED)
            }
            addAction(BluetoothDevice.ACTION_CLASS_CHANGED)
            addAction(BluetoothDevice.ACTION_UUID)

            // addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
//            BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE
//            addAction(BluetoothDevice.ACTION_FOUND)
            // ACTION_BATTERY_LEVEL_CHANGED
            // ACTION_SWITCH_BUFFER_SIZE
//            addAction(BluetoothDevice.ACTION_UUID)
//            addAction(BluetoothDevice.ACTION_NAME_CHANGED)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
//                addAction(BluetoothDevice.ACTION_ALIAS_CHANGED)
//            }
//            addAction(BluetoothDevice.ACTION_PAIRING_REQUEST)
//            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
//            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
//            addAction(BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED)
//            addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
//            addAction(BluetoothDevice.ACTION_CLASS_CHANGED)
        }
        activity!!.registerReceiver(bluetoothBroadcastReceiver, filter)
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity?.unregisterReceiver(bluetoothBroadcastReceiver)
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private val bluetoothBroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            println("### bluetoothBroadcastReceiver: " + intent?.action)
            when (intent?.action) {
                // TODO: STATE_OFF, STATE_TURNING_ON, STATE_ON, STATE_TURNING_OFF
                BluetoothAdapter.ACTION_STATE_CHANGED -> bluetoothStateSink?.success(
                    bluetoothAdapter != null && bluetoothAdapter!!.isEnabled
                )

                BluetoothAdapter.ACTION_DISCOVERY_STARTED -> bluetoothDiscoverySink?.success(true)

                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> bluetoothDiscoverySink?.success(false)

                BluetoothDevice.ACTION_FOUND,
                BluetoothDevice.ACTION_NAME_CHANGED,
                BluetoothDevice.ACTION_ALIAS_CHANGED,
                BluetoothDevice.ACTION_CLASS_CHANGED,
                BluetoothDevice.ACTION_UUID -> {
                    val device: BluetoothDevice? =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(
                                BluetoothDevice.EXTRA_DEVICE,
                                BluetoothDevice::class.java
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        }
                    if (device != null) {
                        val deviceData = convertDeviceToMap(device)
                        deviceFoundSink?.success(deviceData)
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val callback = activityRequestManager.pop(requestCode) ?: return false
        return callback(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        val result = permissionRequestManager.pop(requestCode) ?: return false

        val permissionsResult = mutableMapOf<String, Boolean>()
        for (i in permissions.indices) {
            permissionsResult[permissions[i]] =
                grantResults[i] == PackageManager.PERMISSION_GRANTED
        }

        result.success(permissionsResult)
        return true
    }

    @SuppressLint("HardwareIds")
    override fun onMethodCall(call: MethodCall, result: Result) {
//        // Profiles
//        bluetoothAdapter!!.getProfileProxy()
//        bluetoothAdapter!!.closeProfileProxy()
//        bluetoothAdapter!!.getProfileConnectionState()

//        // Advertisers
//        val bluetoothLeAdvertiser = bluetoothAdapter!!.bluetoothLeAdvertiser
//        bluetoothLeAdvertiser.startAdvertising()
//        bluetoothLeAdvertiser.startAdvertisingSet()
//        bluetoothLeAdvertiser.stopAdvertising()
//        bluetoothLeAdvertiser.stopAdvertisingSet()
//
//        val bluetoothLeScanner = bluetoothAdapter!!.bluetoothLeScanner
//        bluetoothLeScanner.startScan()
//        bluetoothLeScanner.stopScan()
//        bluetoothLeScanner.flushPendingScanResults()
//
//        bluetoothAdapter!!.listenUsingInsecureL2capChannel()
//        bluetoothAdapter!!.listenUsingL2capChannel()
//
//        // BluetoothGatt
        //        device.connectGatt()
//        var bluetoothGatt: BluetoothGatt

//        // ServerSocket
//        var serverSocket: BluetoothServerSocket
//        serverSocket.accept()
//        serverSocket.close()
//        (serverSocket as Object).wait()

        when (call.method) {
            "getSdkVersion" -> result.success(Build.VERSION.SDK_INT)
            "checkPermission" -> checkPermission(call, result)
            "requestPermissions" -> requestPermissions(call, result)
            "isAvailable" -> result.success(bluetoothAdapter != null)
            "isEnabled" -> result.success(bluetoothAdapter!!.isEnabled)
            "enable" -> enable(result)
            "name" -> result.success(bluetoothAdapter!!.name)
//            // "setName" -> result.success(bluetoothAdapter!!.name)
            "address" -> result.success(bluetoothAdapter!!.address)
            "scanMode" -> result.success(bluetoothAdapter!!.scanMode)
//            "getRemoteDevice" -> result.success(bluetoothAdapter!!.getRemoteDevice())
//            //        var device: BluetoothDevice
//            //        device.createBond()
//            //        device.describeContents()
//            //        device.fetchUuidsWithSdp()
//            //        device.setAlias()
//            //        device.setPairingConfirmation()
//            //        device.setPin()
//            //        device.writeToParcel()
            "bondedDevices" -> bondedDevices(result)
            "isDiscovering" -> result.success(bluetoothAdapter!!.isDiscovering)
            "startDiscovery" -> result.success(bluetoothAdapter!!.startDiscovery())
            "cancelDiscovery" -> result.success(bluetoothAdapter!!.cancelDiscovery())
            "rfcommSocketConnect" -> rfcommSocketConnect(call, result)
            "rfcommSocketClose" -> rfcommSocketClose(call, result)
            "rfcommSocketWrite" -> rfcommSocketWrite(call, result)
            "rfcommSocketMaxTransmitPacketSize" -> rfcommSocketMaxTransmitPacketSize(call, result)
            // "rfcommSocketIsConnected" -> rfcommnSocketWrite(call, result)
            // "rfcommSocketMaxTransmitPacketSize" -> rfcommnSocketWrite(call, result)
            // "rfcommSocketRead" -> rfcommnSocketWrite(call, result)
            // "rfcommSocketConnectionType" -> rfcommnSocketWrite(call, result)
            // "rfcommSocketMaxReceivePacketSize" -> rfcommnSocketWrite(call, result)
            // "rfcommSocketConnectionType" -> rfcommnSocketWrite(call, result)
            // device.createInsecureL2capChannel()
            // device.createL2capChannel()

            "isMultipleAdvertisementSupported" -> result.success(
                bluetoothAdapter!!.isMultipleAdvertisementSupported
            )

            "isOffloadedFilteringSupported" -> result.success(
                bluetoothAdapter!!.isOffloadedFilteringSupported
            )

            "isOffloadedScanBatchingSupported" -> result.success(
                bluetoothAdapter!!.isOffloadedScanBatchingSupported
            )

            "isLe2MPhySupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    bluetoothAdapter!!.isLe2MPhySupported else false
            )

            "isLeAudioSupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    bluetoothAdapter!!.isLeAudioBroadcastAssistantSupported else false
            )

            "isLeAudioBroadcastAssistantSupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    bluetoothAdapter!!.isLeAudioBroadcastAssistantSupported else false
            )

            "isLeAudioBroadcastSourceSupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    bluetoothAdapter!!.isLeAudioBroadcastAssistantSupported else false
            )

            "isLeCodedPhySupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    bluetoothAdapter!!.isLeCodedPhySupported else false
            )

            "isLePeriodicAdvertisingSupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    bluetoothAdapter!!.isLePeriodicAdvertisingSupported else false
            )

            "isLeExtendedAdvertisingSupported" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    bluetoothAdapter!!.isLeExtendedAdvertisingSupported else false
            )

            "leMaximumAdvertisingDataLength" ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    result.success(bluetoothAdapter!!.leMaximumAdvertisingDataLength)
                } else {
                    osVersionError(result, Build.VERSION_CODES.O)
                }

            "maxConnectedAudioDevices" ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    result.success(bluetoothAdapter!!.isLeExtendedAdvertisingSupported)
                } else {
                    osVersionError(result, Build.VERSION_CODES.O)
                }

            "discoverableTimeoutMs" ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    result.success(bluetoothAdapter!!.discoverableTimeout?.toMillis())
                } else {
                    osVersionError(result, Build.VERSION_CODES.TIRAMISU)
                }

            else -> result.notImplemented()
        }
    }

    private fun osVersionError(result: Result, versionRequired: Int) {
        result.error(
            "unsupported_android_os_version",
            "Expected OS version: $versionRequired. Current OS Version: ${Build.VERSION.SDK_INT}",
            mapOf(
                "current_os_version" to Build.VERSION.SDK_INT,
                "expected_os_version" to versionRequired,
            )
        )
    }

    private fun checkPermission(call: MethodCall, result: Result) {
        val permission = call.argument<String>("permission")!!
        val permissionResult = ContextCompat.checkSelfPermission(activity!!, permission)
        result.success(permissionResult == PackageManager.PERMISSION_GRANTED)
    }

    private fun requestPermissions(call: MethodCall, result: Result) {
        val permissions = call.argument<List<String>>("permissions")!!
        val requestCode = permissionRequestManager.addRequest(result)
        ActivityCompat.requestPermissions(activity!!, permissions.toTypedArray(), requestCode)
    }


    private fun enable(result: Result) {
        val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        val requestCode = activityRequestManager.addRequest { _, resultCode, _ ->
            result.success(resultCode == Activity.RESULT_OK)
            true
        }
        activity!!.startActivityForResult(enableBtIntent, requestCode)
    }


    private fun convertDeviceToMap(device: BluetoothDevice): Map<String, Any?> {
        return mapOf(
            "name" to device.name,
            "alias" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) device.alias else null,
            "type" to device.type,
            "address" to device.address,
            "bondState" to device.bondState,
            "classOfDevice" to device.bluetoothClass.toString().toInt(16),
            "uuids" to device.uuids?.map { uuid -> uuid.toString() },
        )
    }

    private fun bondedDevices(result: Result) {
        val boundedDevices = bluetoothAdapter!!.bondedDevices
        val boundedDevicesResult = boundedDevices.map(::convertDeviceToMap)
        result.success(boundedDevicesResult)
    }

    private fun rfcommSocketConnect(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")!!
        val secure = call.argument<Boolean>("secure")!!
        val uuid = UUID.fromString(call.argument<String>("serviceRecordUuid")!!)

        val existingSocket = rfcommSockets[address]
        if (existingSocket != null && existingSocket.isConnected) {
            result.success(true)
            return
        }

        executorService!!.execute { // TODO: maybe do in an isolate
            // Cancel discovery because it otherwise slows down the connection.
            bluetoothAdapter!!.cancelDiscovery()
            val device = bluetoothAdapter!!.getRemoteDevice(address)
            val bluetoothSocket: BluetoothSocket
            try {
                bluetoothSocket =
                    if (secure)
                        device.createRfcommSocketToServiceRecord(uuid)
                    else
                        device.createInsecureRfcommSocketToServiceRecord(uuid)
                bluetoothSocket.connect()
            } catch (e: IOException) {
                e.printStackTrace()
                result.success(false)
                // result.error("CONNECTION_FAILED", "Could not connect to device", e.message)
                return@execute
            }
            rfcommSockets[device.address] = bluetoothSocket
            result.success(true)
        }
    }

    private fun rfcommSocketClose(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")!!

        val existingSocket = rfcommSockets[address]
        if (existingSocket == null) {
            result.success(true)
            return
        }

        try {
            existingSocket.close()
        } catch (e: IOException) {
            e.printStackTrace()
            result.success(false)
            return
        }

        rfcommSockets.remove(address)
        result.success(true)
    }

    private fun rfcommSocketWrite(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")!!
        val bytes = call.argument<List<Int>>("bytes")!!

        val socket = rfcommSockets[address]
        if (socket == null) {
            result.success(false)
//            result.error(
//                "WRITE_FAILED_NO_CONNECTION",
//                "Unable to write to device, because there is no connection",
//                null
//            )
            return
        }

        val outputStream: OutputStream
        try {
            outputStream = socket.outputStream
        } catch (e: IOException) {
            result.success(false)
            // result.error("IOException", "Error occurred when creating output stream", e)
            return
        }

        val byteArray: ByteArray =
            bytes.map { (if (it > 127) it - 256 else it).toByte() }.toByteArray()

        try {
            outputStream.write(byteArray)
            outputStream.flush()
        } catch (e: IOException) {
            result.success(false)
            // result.error("IOException", "Error occurred when writing to output stream", e)
            return
        }

        result.success(true)
    }

    private fun rfcommSocketMaxTransmitPacketSize(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            osVersionError(result, Build.VERSION_CODES.M)
            return
        }

        val address = call.argument<String>("address")!!
        val socket = rfcommSockets[address]
        if (socket == null) {
            result.error(
                "SOCKET_NOT_OPEN",
                "Unable to get max packet size, because there is no active open socket with the given address.",
                null
            )
            return
        }

        result.success(socket.maxTransmitPacketSize)
    }
}

// TODO: formalise error messages
// TODO: how does dart format these errors

//            val mmBuffer = ByteArray(1024)
//            var numBytes: Int // bytes returned from read()
//            while (true) {
//                try {
//                    // Read from the InputStream.
//                    numBytes = inputStream.read(mmBuffer)
//                    if (numBytes > 0) {
//                        val data = ByteArray(numBytes)
//                        System.arraycopy(mmBuffer, 0, data, 0, numBytes)
//                        Log.d(
//                            com.tablemi.flutter_bluetooth_basic.FlutterBluetoothBasicPlugin.TAG,
//                            "DATA: " + data.contentToString()
//                        )
//                    }
//                } catch (e: IOException) {
//                    Log.d(
//                        com.tablemi.flutter_bluetooth_basic.FlutterBluetoothBasicPlugin.TAG,
//                        "Input stream was disconnected",
//                        e
//                    )
//                    break
//                }
//            }