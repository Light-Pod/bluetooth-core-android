import 'dart:typed_data';

import 'package:bluetooth_core_android/src/bluetooth_device.dart';
import 'package:bluetooth_core_android/src/permissions.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_core_android_method_channel.dart';

abstract class BluetoothCoreAndroidPlatform extends PlatformInterface {
  /// Constructs a BluetoothCoreAndroidPlatform.
  BluetoothCoreAndroidPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothCoreAndroidPlatform _instance =
      MethodChannelBluetoothCoreAndroid();

  /// The default instance of [BluetoothCoreAndroidPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothCoreAndroid].
  static BluetoothCoreAndroidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothCoreAndroidPlatform] when
  /// they register themselves.
  static set instance(BluetoothCoreAndroidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<bool> getBluetoothStateStream();

  Stream<bool> getBluetoothDiscoveryStream();

  Stream<BluetoothDevice> getDeviceFoundStream();

  Future<int> getSdkVersion();

  Future<bool> checkPermission(AndroidBluetoothPermission permission) {
    throw UnimplementedError('enable() has not been implemented.');
  }

  Future<bool> hasPermissions(
      List<AndroidBluetoothPermission> permissions) async {
    for (final permission in permissions) {
      if (!(await checkPermission(permission))) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, bool>> requestPermissions(
      List<AndroidBluetoothPermission> permissions) {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  Future<bool> isEnabled() {
    throw UnimplementedError('isEnabled() has not been implemented.');
  }

  Future<bool> enable() {
    throw UnimplementedError('enable() has not been implemented.');
  }

  Future<List<BluetoothDevice>> bondedDevices();

  Future<bool> startDiscovery();

  Future<bool> cancelDiscovery();

  Future<bool> isDiscovering();

  Future<bool> rfcommSocketConnect({
    required String address,
    required bool secure,
    required String serviceRecordUuid,
  });

  Future<bool> rfcommSocketClose({required String address});

  Future<bool> rfcommSocketWrite({
    required String address,
    required Uint8List bytes,
  });

// TODO: check if already connected???
}
