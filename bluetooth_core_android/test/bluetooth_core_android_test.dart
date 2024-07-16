import 'package:bluetooth_core_android/src/class_of_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_core_android/bluetooth_core_android.dart';
import 'package:bluetooth_core_android/bluetooth_core_android_platform_interface.dart';
import 'package:bluetooth_core_android/bluetooth_core_android_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockBluetoothCoreAndroidPlatform
//     with MockPlatformInterfaceMixin
//     implements BluetoothCoreAndroidPlatform {
//
//   @override
//   Future<bool> isAvailable() => Future.value(true);
//   @override
//   Future<bool> isEnabled() => Future.value(true);
// }

void main() {
  // final BluetoothCoreAndroidPlatform initialPlatform = BluetoothCoreAndroidPlatform.instance;
  //
  // test('$MethodChannelBluetoothCoreAndroid is the default instance', () {
  //   expect(initialPlatform, isInstanceOf<MethodChannelBluetoothCoreAndroid>());
  // });
  //
  // test('getPlatformVersion', () async {
  //   BluetoothCoreAndroid bluetoothCoreAndroidPlugin = BluetoothCoreAndroid();
  //   MockBluetoothCoreAndroidPlatform fakePlatform = MockBluetoothCoreAndroidPlatform();
  //   BluetoothCoreAndroidPlatform.instance = fakePlatform;
  //
  //   expect(await bluetoothCoreAndroidPlugin.isAvailable(), true);
  // });

  test('getServiceClassFromCod', () async {
    const cod = 0x70680;
    final serviceClasses = getServiceClassFromCod(cod);
    expect(
      serviceClasses,
        {
          ServiceClass.positioning,
          ServiceClass.networking,
          ServiceClass.rendering
        }
    );
  });

  test('getDeviceClassFromCod', () async {
    const cod = 0x70680;
    final deviceClass = DeviceClass.createFromCod(cod);
    expect(deviceClass.runtimeType, ImagingDeviceType);
    expect(deviceClass.minorClass, ImagingMinorDeviceType.printer);
  });
}
