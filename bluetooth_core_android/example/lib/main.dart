import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluetooth_core_android/bluetooth_core_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  late bool _isAvailable;
  late bool _isEnabled;
  final _bluetoothCoreAndroidPlugin = BluetoothCoreAndroid();

  @override
  void initState() {
    super.initState();
    initBluetoothState();
  }

  Future<void> initBluetoothState() async {
    setState(() {
      loading = true;
    });

    final isAvailable = await _bluetoothCoreAndroidPlugin.isAvailable();
    final isEnabled = await _bluetoothCoreAndroidPlugin.isEnabled();

    if (!mounted) return;

    setState(() {
      loading = false;
      _isAvailable = isAvailable;
      _isEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Android Bluetooth Core Example App'),
        ),
        body: _Content(),
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({super.key});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  bool loading = true;
  late bool _isAvailable;
  late bool _isEnabled;
  late bool _isDiscovering;
  final _bluetoothCoreAndroidPlugin = BluetoothCoreAndroid();
  BluetoothDevice? _selectedDevice;

  static const EventChannel eventChannel = EventChannel('found_device_event');

  @override
  void initState() {
    super.initState();
    initBluetoothState();
    // _bluetoothCoreAndroidPlugin.api.getDeviceFoundStream().listen((event) {
    //   print('Received event: $event');
    // }, onError: (error) {
    //   print('Received error: $error');
    // });
  }

  Future<void> initBluetoothState() async {
    setState(() {
      loading = true;
    });

    final isAvailable = await _bluetoothCoreAndroidPlugin.isAvailable();
    final isEnabled = await _bluetoothCoreAndroidPlugin.isEnabled();
    final isDiscovering = await _bluetoothCoreAndroidPlugin.isDiscovering();

    if (!mounted) return;

    setState(() {
      loading = false;
      _isAvailable = isAvailable;
      _isEnabled = isEnabled;
      _isDiscovering = isDiscovering;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
              child: Column(
                children: [
                  Text('Available: $_isAvailable'),
                  ..._isAvailable
                      ? [
                          Text('Enabled: $_isEnabled'),
                          if (!_isEnabled)
                            OutlinedButton(
                              onPressed: enableBluetooth,
                              child: const Text('Enable Bluetooth'),
                            ),
                          OutlinedButton(
                            onPressed: getBondedDevices,
                            child: const Text('Get Bonded Devices'),
                          ),
                          StreamBuilder(
                            initialData: _isDiscovering,
                            stream: _bluetoothCoreAndroidPlugin
                                .bluetoothDiscoveryStream,
                            builder: (context, snapshot) {
                              final isDiscovering = snapshot.data!;

                              return Column(children: [
                                Text('Is Discovering: $isDiscovering'),
                                if (!isDiscovering)
                                  OutlinedButton(
                                    onPressed: scan,
                                    child: const Text('Start Scan'),
                                  )
                                else
                                  OutlinedButton(
                                    onPressed: stopScan,
                                    child: const Text('Stop Scan'),
                                  ),
                              ]);
                            },
                          ),
                          StreamBuilder(
                            initialData:
                                _bluetoothCoreAndroidPlugin.scanResults,
                            stream:
                                _bluetoothCoreAndroidPlugin.scanResultsStream,
                            builder: (context, snapshot) {
                              return _Devices(
                                snapshot.data!,
                                selectedDevice: _selectedDevice,
                                onSelect: (device) {
                                  setState(() {
                                    _selectedDevice = device;
                                  });
                                },
                              );
                            },
                          ),
                          if (_selectedDevice != null) ...[
                            OutlinedButton(
                              onPressed: connect,
                              child: const Text('Connect'),
                            ),
                            OutlinedButton(
                              onPressed: disconnect,
                              child: const Text('Disconnect'),
                            ),
                            OutlinedButton(
                              onPressed: write,
                              child: const Text('Write'),
                            ),
                          ],
                        ]
                      : [],
                  OutlinedButton(
                    child: const Text('Refresh'),
                    onPressed: () {
                      initBluetoothState();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void enableBluetooth() async {
    print("ENABLING");
    final bool result;
    try {
      result = await _bluetoothCoreAndroidPlugin.enable();
    } on PermissionException {
      showErrorSnackBar(context, 'Unable to Permission error');
      return;
    }
    if (result) {
      showSnackBar(context, 'Bluetooth Enabled!');
    } else {
      showErrorSnackBar(context, 'Bluetooth not enabled!');
    }
    initBluetoothState();
  }

  void getBondedDevices() async {
    final result = await _bluetoothCoreAndroidPlugin.bondedDevices();
    print(result);
  }

  void scan() async {
    try {
      final result = await _bluetoothCoreAndroidPlugin.startDiscovery();
      if (result) {
        showSnackBar(context, 'Scanning started');
      } else {
        showErrorSnackBar(context, 'Failed to start scan');
      }
    } on PermissionException {
      showErrorSnackBar(context, 'Permission error');
    }
  }

  void stopScan() async {
    try {
      final result = await _bluetoothCoreAndroidPlugin.cancelDiscovery();
      if (result) {
        showSnackBar(context, 'Scanning stopped');
      } else {
        showErrorSnackBar(context, 'Failed to stop scan');
      }
    } on PermissionException {
      showErrorSnackBar(context, 'Permission error');
    }
  }

  void connect() async {
    try {
      final result = await _bluetoothCoreAndroidPlugin.rfcommSocketConnect(
        address: _selectedDevice!.address,
        secure: false,
      );
      if (result) {
        showSnackBar(context, 'Connected');
      } else {
        showErrorSnackBar(context, 'Failed to connect');
      }
    } on PermissionException {
      showErrorSnackBar(context, 'Permission error');
    }
  }

  void disconnect() async {
    try {
      final result = await _bluetoothCoreAndroidPlugin.rfcommSocketClose(
        address: _selectedDevice!.address,
      );
      if (result) {
        showSnackBar(context, 'Disconnected');
      } else {
        showErrorSnackBar(context, 'Failed to disconnect');
      }
    } on PermissionException {
      showErrorSnackBar(context, 'Permission error');
    }
  }

  void write() async {
    try {
      final result = await _bluetoothCoreAndroidPlugin.rfcommSocketWrite(
        address: _selectedDevice!.address,
        bytes: utf8.encode("Hello World\n\n\n\nhi you!\n\n"),
      );
      if (result) {
        showSnackBar(context, 'Write complete!');
      } else {
        showErrorSnackBar(context, 'Failed to write');
      }
    } on PermissionException {
      showErrorSnackBar(context, 'Permission error');
    }
  }
}

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: Colors.green,
      showCloseIcon: true,
    ),
  );
}

void showErrorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: Colors.red,
      showCloseIcon: true,
    ),
  );
}

class _Devices extends StatelessWidget {
  final BluetoothDevice? selectedDevice;
  final Function(BluetoothDevice) onSelect;

  final List<BluetoothDevice> devices;

  const _Devices(
    this.devices, {
    super.key,
    required this.selectedDevice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.all(8),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: devices.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: const Color(0xffcccccc),
        ),
        itemBuilder: (context, index) {
          final device = devices[index];
          final isSelected = device.address == selectedDevice?.address;

          return GestureDetector(
            onTap: () => onSelect(device),
            child: Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isSelected ? Colors.tealAccent : null,
              child: Row(
                children: [
                  Icon(device.icon),
                  Expanded(
                    child: Text(
                      '${device.name ?? '<Unknown Device>'} (${device.address})',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
          // return Column(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     Text(device.name ?? '<Unkown Device>'),
          //   ],
          // );
        },
      ),
    );
  }
}
