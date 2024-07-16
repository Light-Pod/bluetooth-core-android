enum AndroidBluetoothPermission {
  bluetooth('android.permission.BLUETOOTH'),
  bluetoothAdmin('android.permission.BLUETOOTH_ADMIN'),
  bluetoothScan('android.permission.BLUETOOTH_SCAN'),
  bluetoothConnect('android.permission.BLUETOOTH_CONNECT'),
  bluetoothAdvertise('android.permission.BLUETOOTH_ADVERTISE'),
  bluetoothPrivileged('android.permission.BLUETOOTH_PRIVILEGED'),
  manageDevicePolicyBluetooth('android.permission.MANAGE_DEVICE_POLICY_BLUETOOTH');
  
  const AndroidBluetoothPermission(this.value);

  final String value;
}
