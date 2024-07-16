import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_core_android/src/bluetooth_device.dart';
import 'package:bluetooth_core_android/src/permissions.dart';
import 'bluetooth_core_android_platform_interface.dart';

export 'src/bluetooth_device.dart';

class BluetoothCoreAndroid {
  static BluetoothCoreAndroid? _instance;

  /// Get instance using singleton pattern
  static BluetoothCoreAndroid get instance {
    return _instance ??= BluetoothCoreAndroid();
  }

  int? _sdkVersion;
  final BluetoothCoreAndroidPlatform api =
      BluetoothCoreAndroidPlatform.instance;

  late final Stream<bool> bluetoothStateStream;

  /// Fetches all the devices found so far. Is cleared after running "startDiscovery" method
  final _scanResultsController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final List<BluetoothDevice> _scanResults = [];

  BluetoothCoreAndroid() {
    bluetoothStateStream = api.getBluetoothStateStream();
    api.getDeviceFoundStream().listen((device) {
      _scanResults.removeWhere((d) => device.address == d.address);
      _scanResults.add(device);
      _scanResults.sort((d1, d2) {
        // (1) Devices with a name should appear before devices without a name
        if (d1.name != null && d2.name == null) {
          return -1;
        }
        if (d1.name == null && d2.name != null) {
          return 1;
        }
        // (2) Devices should appear in alphabetical order
        if (d1.name != null && d2.name != null && d1.name != d2.name) {
          return d1.name!.compareTo(d2.name!);
        }
        // (3) Devices with identical names should be compared to their address
        return d1.address.compareTo(d2.address);
      });
      _scanResultsController.add(_scanResults);
    });
  }

  List<BluetoothDevice> get scanResults => List.unmodifiable(_scanResults);

  Stream<List<BluetoothDevice>> get scanResultsStream =>
      _scanResultsController.stream;

  // Stream<bool> get bluetoothStateStream => api.getBluetoothStateStream();

  Stream<bool> get bluetoothDiscoveryStream =>
      api.getBluetoothDiscoveryStream();

  void dispose() {
    _scanResultsController.close();
  }

  Future<int> getSdkVersion() async {
    _sdkVersion ??= await api.getSdkVersion();
    return _sdkVersion!;
  }

  Future<bool> isAvailable() {
    return api.isAvailable();
  }

  Future<bool> isEnabled() async {
    return await isAvailable() && await api.isEnabled();
  }

  Future<void> requestPermissions(
    List<AndroidBluetoothPermission> permissions,
  ) async {
    final List<AndroidBluetoothPermission> deniedPermission = [];
    for (final permission in permissions) {
      if (!await api.checkPermission(permission)) {
        deniedPermission.add(permission);
      }
    }
    if (deniedPermission.isEmpty) {
      return; // All permission already granted
    }
    final result = await api.requestPermissions(deniedPermission);
    if (result.values.every((granted) => granted)) {
      return; // All permissions granted
    }
    throw PermissionException();
  }

  Future<void> requestBluetoothConnectPermission() async {
    final permission = (await getSdkVersion()) >= 31
        ? AndroidBluetoothPermission.bluetoothConnect
        : AndroidBluetoothPermission.bluetooth;

    await requestPermissions([permission]);
  }

  Future<void> requestBluetoothScanPermission() async {
    /*
    For Android 6.0 (API level 23) and above, you need to request the
    ACCESS_FINE_LOCATION permission at runtime. For Android 12 and higher,
    you also need to request BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions at runtime.
     */
    // TODO: fine-tune, as can change depending on manifest
    final permissions = (await getSdkVersion()) >= 31
        ? [
            AndroidBluetoothPermission.bluetoothScan,
            AndroidBluetoothPermission.bluetoothConnect,
            // TODO: can be for location as well if SDK less than and needed for location
          ]
        : [AndroidBluetoothPermission.bluetoothAdmin];

    await requestPermissions(permissions);
  }

  Future<void> requestBluetoothStopScanPermission() async {
    // TODO: fine-tune
    final permissions = (await getSdkVersion()) >= 31
        ? [AndroidBluetoothPermission.bluetoothScan]
        : [AndroidBluetoothPermission.bluetoothAdmin];

    await requestPermissions(permissions);
  }

  Future<bool> enable() async {
    await requestBluetoothConnectPermission();
    return await api.enable();
  }

  Future<List<BluetoothDevice>> bondedDevices() {
    return api.bondedDevices();
  }

  Future<bool> isDiscovering() async {
    return await api.isEnabled() ? await api.isDiscovering() : false;
  }

  Future<bool> startDiscovery() async {
    _scanResults.clear();
    _scanResultsController.add(_scanResults);
    if (!await api.isEnabled()) {
      return false;
    }
    if (!await cancelDiscovery()) {
      return false;
    }
    await requestBluetoothScanPermission();
    return await api.startDiscovery();
  }

  Future<bool> cancelDiscovery() async {
    if (!await api.isEnabled()) {
      return true;
    }
    await requestBluetoothStopScanPermission();
    return await isDiscovering() ? await api.cancelDiscovery() : true;
  }

  // Future<bool> write({
  //   required String address,
  //   required Uint8List bytes,
  // }) async {
  //   if (!await api.isEnabled()) {
  //     return false;
  //   }
  //
  //   // TODO: check if connected already
  //   final connected = await api.rfcommSocketConnect(
  //     address: address,
  //     secure: false,
  //     serviceRecordUuid: '00001101-0000-1000-8000-00805F9B34FB',
  //   );
  //
  //   if (!connected) {
  //     return false;
  //   }
  //
  //   /*
  //   var offset = 0
  //       while (offset < data.size) {
  //           val chunkSize = minOf(maxChunkSize, data.size - offset)
  //           val chunk = data.copyOfRange(offset, offset + chunkSize)
  //           try {
  //               outputStream?.write(chunk)
  //           } catch (e: IOException) {
  //               Log.e("Bluetooth", "Error sending data", e)
  //               break
  //           }
  //           offset += chunkSize
  //       }
  //    */
  //
  //   try {
  //     // TODO: chunk
  //     return await api.rfcommSocketWrite(address: address, bytes: bytes);
  //   } catch (e) {
  //     return false;
  //   } finally {
  //     await api.rfcommSocketClose(address: address);
  //   }
  // }

  Future<bool> rfcommSocketConnect({
    required String address,
    required bool secure,
  }) async {
    if (!await api.isEnabled()) {
      return false;
    }
    await requestBluetoothConnectPermission();

    return await api.rfcommSocketConnect(
      address: address,
      secure: secure,
      serviceRecordUuid: '00001101-0000-1000-8000-00805F9B34FB',
    );
  }

  Future<bool> rfcommSocketClose({required String address}) async {
    return await api.rfcommSocketClose(address: address);
  }

  Future<bool> rfcommSocketWrite({
    required String address,
    required List<int> bytes,
  }) async {
    return await api.rfcommSocketWrite(address: address, bytes: bytes);
  }
}

// TODO: use below exceptions

abstract class BluetoothException implements Exception {
  final String message;

  BluetoothException(this.message);
}

class PermissionException extends BluetoothException {
  PermissionException([String? message])
      : super(message ?? 'Permission Denied'); // TODO

// @override
// String toString() {
//   return "MyCustomException: $message";
// }
}

class BluetoothNotAvailableException extends BluetoothException {
  BluetoothNotAvailableException([String? message])
      : super(message ?? 'Bluetooth not available on this device!');
// BluetoothNotAvailableException(
//     super.
//     );
//
}

class BluetoothNotEnabledException extends BluetoothException {
  BluetoothNotEnabledException([String? message])
      : super(message ?? 'Bluetooth not enabled!');
}

class UnableToConnectToDevice extends BluetoothException {
  UnableToConnectToDevice([String? message])
      : super(message ?? 'Unable to connect to Bluetooth Device!');
}

class UnableToWriteToDevice extends BluetoothException {
  UnableToWriteToDevice([String? message])
      : super(message ?? 'Unable to write to Bluetooth Device!');
}

class UnableToDisconnectFromDevice extends BluetoothException {
  UnableToDisconnectFromDevice([String? message])
      : super(message ?? 'Unable to disconnect from Bluetooth Device!');
}
