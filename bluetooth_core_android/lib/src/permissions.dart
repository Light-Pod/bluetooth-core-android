enum AndroidBluetoothPermission {
  bluetooth('android.permission.BLUETOOTH'),
  bluetoothAdmin('android.permission.BLUETOOTH_ADMIN'),
  /// Requires Android API Level 31
  bluetoothScan('android.permission.BLUETOOTH_SCAN'),
  /// Requires Android API Level 31
  bluetoothConnect('android.permission.BLUETOOTH_CONNECT'),
  /// Requires Android API Level 31
  bluetoothAdvertise('android.permission.BLUETOOTH_ADVERTISE'),
  bluetoothPrivileged('android.permission.BLUETOOTH_PRIVILEGED'),
  manageDevicePolicyBluetooth('android.permission.MANAGE_DEVICE_POLICY_BLUETOOTH'),
  accessFineLocation('android.permission.ACCESS_FINE_LOCATION');

  const AndroidBluetoothPermission(this.value);

  final String value;
}
