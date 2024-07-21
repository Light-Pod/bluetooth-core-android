class BluetoothSocket {
  final String id;
  final String type;

  /// isConnected is not a reliable way to check if the bluetooth connection is
  /// still alive. Consider reading from input stream for expected data instead
  final bool isConnected;
  /// Supported on Android Build Version >= 23
  final int? connectionType;
  /// Supported on Android Build Version >= 23
  final int? maxReceivePacketSize;
  /// Supported on Android Build Version >= 23
  final int? maxTransmitPacketSize;

  BluetoothSocket({
    required this.id,
    required this.type,
    required this.isConnected,
    required this.connectionType,
    required this.maxReceivePacketSize,
    required this.maxTransmitPacketSize,
  });

  factory BluetoothSocket.fromJson(Map<String, dynamic> json) {
    return BluetoothSocket(
      id: json['id'],
      type: json['type'],
      isConnected: json['isConnected'],
      connectionType: json['connectionType'],
      maxReceivePacketSize: json['maxReceivePacketSize'],
      maxTransmitPacketSize: json['maxTransmitPacketSize'],
    );
  }
}
