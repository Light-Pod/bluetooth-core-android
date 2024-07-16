import 'package:bluetooth_core_android/src/class_of_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BluetoothDevice {
  final String? name;
  final String? alias;
  final DeviceType? type;
  final String address;
  final int classOfDevice;
  final BondState bondState;
  final Set<ServiceClass> serviceClasses;
  final DeviceClass deviceClass;

  BluetoothDevice({
    required this.name,
    required this.alias,
    required this.type,
    required this.address,
    required this.classOfDevice,
    required this.bondState,
  })  : serviceClasses = getServiceClassFromCod(classOfDevice),
        deviceClass = DeviceClass.createFromCod(classOfDevice);

  IconData get icon {
    switch (deviceClass.runtimeType) {
      case == ComputerDeviceType:
        return Icons.computer;
      case == PhoneDeviceType:
        return Icons.phone;
      case == LanNetworkAccessPointDeviceType:
        return Icons.router;
      case == AudioVideoDeviceType:
        return Icons.phone;
      case == PeripheralDeviceType:
        return Icons.mouse;
      case == ImagingDeviceType:
        switch ((deviceClass as ImagingDeviceType).minorClass) {
          case ImagingMinorDeviceType.scanner:
            return Icons.scanner;
          case ImagingMinorDeviceType.camera:
            return Icons.camera_alt;
          case ImagingMinorDeviceType.display:
            return Icons.monitor;
          case ImagingMinorDeviceType.printer:
            return Icons.print;
          default:
            return Icons.bluetooth;
        }
      case == WearableDeviceType:
        return Icons.watch;
      case == ToyDeviceType:
        return Icons.smart_toy;
      case == MiscellaneousDeviceType:
      default:
        return Icons.bluetooth;
    }
    // case 3:
    // return LanNetworkAccessPointDeviceType.fromMinorDevice(minorDeviceClass);
    // case 4:
    // return AudioVideoDeviceType.fromMinorDevice(minorDeviceClass);
    // case 5:
    // return PeripheralDeviceType.fromMinorDevice(minorDeviceClass);
    // case 6:
    // return ImagingDeviceType.fromMinorDevice(minorDeviceClass);
    // case 7:
    // return WearableDeviceType.fromMinorDevice(minorDeviceClass);
    // case 8:
    // return ToyDeviceType.fromMinorDevice(minorDeviceClass);
    // case 31:
    // default:
    // return UncategorizedDeviceType.fromMinorDevice(minorDeviceClass);
  }

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(
      name: json['name'],
      alias: json['alias'],
      type: convertToBluetoothDeviceType(json['type']),
      address: json['address'] as String,
      classOfDevice: json['classOfDevice'],
      bondState: convertToBondState(json['bondState']),
    );
  }

  @override
  String toString() {
    // return 'BluetoothDevice{name: $name, alias: $alias, type: $type, address: $address, bondState: $bondState}';
    return 'BluetoothDevice{name: $name, alias: $alias, type: $type, address: $address,'
        ' bluetoothClass: $classOfDevice, bonSate: $bondState, cod: $classOfDevice, deviceClass: ${deviceClass.name}}';
  }
}

enum DeviceType {
  classic,
  le,
  dual,
  unknown;
}

enum BondState {
  none, // 10
  bonding, // 11
  bonded, // 12
}

DeviceType convertToBluetoothDeviceType(int type) {
  switch (type) {
    case 1:
      return DeviceType.classic;
    case 2:
      return DeviceType.le;
    case 3:
      return DeviceType.dual;
    case 0:
    default:
      return DeviceType.unknown;
  }
}

BondState convertToBondState(int bondState) {
  switch (bondState) {
    case 11:
      return BondState.bonding;
    case 12:
      return BondState.bonded;
    case 10:
    default:
      return BondState.none;
  }
}
