/// Cod stands for class of device.
/// It is a 24 Bit Bluetooth CoD is used to describe the type of device, and
/// the services it provides
/// - First 11 bits (13-23): Service Class
/// - Next 5 bits (8-12): Major Device class
/// - Next 6 Bits (2-7): Minor class
/// - Next 2 bits (0-1): Format type (00)
///
/// @link https://www.ampedrftech.com/guides/cod_definition.pdf
/// @link https://bitbucket.org/bluetooth-SIG/public/src/main/assigned_numbers/core/class_of_device.yaml

import 'package:flutter/foundation.dart';

/// Gets the bits in the specified range, with right-most bit numbered bit 0
/// e.g.
/// ```
/// _getBitsInRange(0b110101101, 3, 6) => 0b0101
/// ```
int _getBitsInRange(int number, int startBit, int endBit) {
  assert(startBit > 0);
  // assert(endBit <= 32);
  assert(startBit <= endBit);

  final numberOfBits = endBit - startBit + 1;
  final mask = (1 << numberOfBits) - 1;
  return (number >> startBit) & mask;
}

/// Checks if the bit is enabled at the specified bit, with the right-most bit
/// numbered bit 0.
///
/// e.g.
/// ```
/// _isBitEnabled(0b1100001000, 3) => true
/// ```
bool _isBitEnabled(int number, int bitPosition) {
  return number & (1 << bitPosition) != 0;
}

enum ServiceClass {
  limitedDiscoverableMode('Limited Discoverable Mode', 13),
  leAudio('LE audio', 14),
  reservedForFutureUse('Reserved for Future Use', 15),
  positioning('Positioning', 16),

  /// e.g. LAN, Ad hoc
  networking('Networking', 17),

  /// e.g. Printing, Speakers
  rendering('Rendering', 18),

  /// e.g. Scanner, Microphone
  capturing('Capturing', 19),

  /// e.g. v-Inbox, v-Folder
  objectTransfer('Object Transfer', 20),

  /// e.g. Speaker, Microphone, Headset service
  audio('Audio', 21),

  /// e.g. Cordless telephony, Modem, Headset service
  telephony('Telephony', 22),

  /// e.g. WEB-server, WAP-server
  information('Information', 23);

  final String name;
  final int bit;

  const ServiceClass(this.name, this.bit);
}

Set<ServiceClass> getServiceClassFromCod(int cod) {
  return ServiceClass.values
      .where((serviceClass) => _isBitEnabled(cod, serviceClass.bit))
      .toSet();
}

@immutable
abstract class DeviceClass<T extends MinorDeviceType> {
  final String name;
  final T? minorClass;

  const DeviceClass({required this.name, required this.minorClass});

  static DeviceClass createFromCod(int cod) {
    final int majorDeviceClass = _getBitsInRange(cod, 8, 12);
    final int minorDeviceClass = _getBitsInRange(cod, 2, 7);

    switch (majorDeviceClass) {
      case 0:
        return MiscellaneousDeviceType.fromMinorDevice(minorDeviceClass);
      case 1:
        return ComputerDeviceType.fromMinorDevice(minorDeviceClass);
      case 2:
        return PhoneDeviceType.fromMinorDevice(minorDeviceClass);
      case 3:
        return LanNetworkAccessPointDeviceType.fromMinorDevice(minorDeviceClass);
      case 4:
        return AudioVideoDeviceType.fromMinorDevice(minorDeviceClass);
      case 5:
        return PeripheralDeviceType.fromMinorDevice(minorDeviceClass);
      case 6:
        return ImagingDeviceType.fromMinorDevice(minorDeviceClass);
      case 7:
        return WearableDeviceType.fromMinorDevice(minorDeviceClass);
      case 8:
        return ToyDeviceType.fromMinorDevice(minorDeviceClass);
      case 31:
      default:
        return UncategorizedDeviceType.fromMinorDevice(minorDeviceClass);
    }
  }
}

abstract class MinorDeviceType {
  abstract final String name;
  abstract final int number;
}

T? getMinorDeviceClass<T extends MinorDeviceType>({
  required int number,
  required List<T> values,
}) {
  for (var minorType in values) {
    if (number == minorType.number) {
      return minorType;
    }
  }
  return null;
}

class MiscellaneousDeviceType extends DeviceClass {
  const MiscellaneousDeviceType({required super.minorClass})
      : super(name: 'Miscellaneous');

  factory MiscellaneousDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return const MiscellaneousDeviceType(minorClass: null);
  }
}

class UncategorizedDeviceType extends DeviceClass {
  const UncategorizedDeviceType({required super.minorClass})
      : super(name: 'Miscellaneous');

  factory UncategorizedDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return const UncategorizedDeviceType(minorClass: null);
  }
}

// /// Empty placeholder value to suppress static errors for MiscellaneousDeviceType
// enum NoMinorDeviceType implements MinorDeviceType {
//   unknown(-1, 'unknown');
//
//   @override
//   final int number;
//   @override
//   final String name;
//
//   const NoMinorDeviceType(this.number, this.name);
// }

class ComputerDeviceType extends DeviceClass<ComputerMinorDeviceType> {
  const ComputerDeviceType({required super.minorClass})
      : super(name: 'Computer');

  factory ComputerDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return ComputerDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: ComputerMinorDeviceType.values,
      ),
    );
  }
}

enum ComputerMinorDeviceType implements MinorDeviceType {
  uncategorized(0, 'Uncategorized'),
  desktopWorkstation(1, 'Desktop Workstation'),
  serverClassComputer(2, 'Server-class Computer'),
  laptop(3, 'Laptop'),
  handheld(4, 'Handheld PC/PDA (clamshell)'),
  palmSizePCOrPda(5, 'Palm-size PC/PDA'),
  wearableComputer(6, 'Wearable Computer (watch size)'),
  tablet(7, 'Tablet');

  @override
  final int number;
  @override
  final String name;

  const ComputerMinorDeviceType(this.number, this.name);
}

class PhoneDeviceType extends DeviceClass<PhoneMinorDeviceType> {
  const PhoneDeviceType({required super.minorClass}) : super(name: 'Phone');

  factory PhoneDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return PhoneDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: PhoneMinorDeviceType.values,
      ),
    );
  }
}

enum PhoneMinorDeviceType implements MinorDeviceType {
  uncategorized(0, 'Uncategorized'),
  cellular(1, 'Cellular'),
  cordless(2, 'Cordless'),
  smartphone(3, 'Smartphone'),
  modemOrGateway(4, 'Wired Modem or Voice Gateway'),
  isdn(5, 'Common ISDN Access');

  @override
  final int number;
  @override
  final String name;

  const PhoneMinorDeviceType(this.number, this.name);
}

class LanNetworkAccessPointDeviceType
    extends DeviceClass<LanNetworkAccessPointMinorDeviceType> {
  const LanNetworkAccessPointDeviceType({required super.minorClass})
      : super(name: 'LAN/Network Access Point');

  factory LanNetworkAccessPointDeviceType.fromMinorDevice(
      int minorDeviceTypeNumber) {
    return LanNetworkAccessPointDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: LanNetworkAccessPointMinorDeviceType.values,
      ),
    );
  }
}

enum LanNetworkAccessPointMinorDeviceType implements MinorDeviceType {
  fullyAvailable(0, 'Fully Available'),
  utilised1To17(1, '1% to 17% utilized'),
  utilised17To33(2, '17% to 33% utilized'),
  utilised33To50(3, '33% to 50% utilized'),
  utilised50To67(4, '50% to 67% utilized'),
  utilised67To83(5, '67% to 83% utilized'),
  utilised83To99(6, '83% to 99% utilized'),
  noServiceAvailable(7, 'No service available');

  // TODO: subminor

  @override
  final int number;
  @override
  final String name;

  const LanNetworkAccessPointMinorDeviceType(this.number, this.name);
}

class AudioVideoDeviceType extends DeviceClass<AudioVideoMinorDeviceType> {
  const AudioVideoDeviceType({required super.minorClass})
      : super(name: 'Audio/Video');

  factory AudioVideoDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return AudioVideoDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: AudioVideoMinorDeviceType.values,
      ),
    );
  }
}

enum AudioVideoMinorDeviceType implements MinorDeviceType {
  uncategorized(0, 'Uncategorized'),
  wearableHeadset(1, 'Wearable Headset Device'),
  handsFree(2, 'Hands-free Device'),
  // reservedForFutureUse(3, 'Reserved for Future Use'),
  microphone(4, 'Microphone'),
  loudspeaker(5, 'Loudspeaker'),
  headphones(6, 'Headphones'),
  portableAudio(7, 'Portable Audio'),
  carAudio(8, 'Car Audio'),
  setTopBox(9, 'Set-top Box'),
  hifiAudioDevice(10, 'HiFi Audio Device'),
  vcr(11, 'VCR'),
  videoCamera(12, 'Video Camera'),
  camcorder(13, 'Camcorder'),
  videoMonitor(14, 'Video Monitor'),
  videoDisplayAndLoudspeaker(15, 'Video Display and Loudspeaker'),
  videoConferencing(16, 'Video Conferencing'),
  // reservedForFutureUse2(17, 'Reserved for Future Use'),
  gamingToy(18, 'Gaming/Toy');

  @override
  final int number;
  @override
  final String name;

  const AudioVideoMinorDeviceType(this.number, this.name);
}

class PeripheralDeviceType extends DeviceClass<PeripheralMinorDeviceType> {
  const PeripheralDeviceType({required super.minorClass})
      : super(name: 'Peripheral');

  factory PeripheralDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return PeripheralDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: PeripheralMinorDeviceType.values,
      ),
    );
  }
}

enum PeripheralMinorDeviceType implements MinorDeviceType { // TODO: fix
  uncategorized(0, 'Uncategorized'),
  joystick(1, 'Keyboard'),
  gamepad(2, 'Pointing Device'),
  remoteControl(3, 'Combo Keyboard/Pointing Device');

  // TODO: this one more complex!!! see docs

  @override
  final int number;
  @override
  final String name;

  const PeripheralMinorDeviceType(this.number, this.name);
}

class ImagingDeviceType extends DeviceClass<ImagingMinorDeviceType> {
  const ImagingDeviceType({required super.minorClass}) : super(name: 'Imaging');

  factory ImagingDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return ImagingDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: ImagingMinorDeviceType.values,
      ),
    );
  }
}

// TODO: devices can have multiple device types for imaging
enum ImagingMinorDeviceType implements MinorDeviceType {
  printer(32, 'Printer'),
  display(4, 'Display'),
  camera(8, 'Camera'),
  scanner(16, 'Scanner');

  // display(4, 'Display'),
  // camera(5, 'Camera'),
  // scanner(6, 'Scanner'),
  // printer(7, 'Printer');

  // TODO: subminor

  @override
  final int number;
  @override
  final String name;

  const ImagingMinorDeviceType(this.number, this.name);
}

class WearableDeviceType extends DeviceClass<WearableMinorDeviceType> {
  const WearableDeviceType({required super.minorClass})
      : super(name: 'Wearable');

  factory WearableDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return WearableDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: WearableMinorDeviceType.values,
      ),
    );
  }
}

enum WearableMinorDeviceType implements MinorDeviceType {
  wristwatch(1, 'Wristwatch'),
  pager(2, 'Pager'),
  jacket(3, 'Jacket'),
  helmet(4, 'Helmet'),
  glasses(5, 'Glasses'),
  pin(6, 'Pin');

  @override
  final int number;
  @override
  final String name;

  const WearableMinorDeviceType(this.number, this.name);
}

class ToyDeviceType extends DeviceClass<ToyMinorDeviceType> {
  const ToyDeviceType({required super.minorClass}) : super(name: 'Toy');

  factory ToyDeviceType.fromMinorDevice(int minorDeviceTypeNumber) {
    return ToyDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: ToyMinorDeviceType.values,
      ),
    );
  }
}

enum ToyMinorDeviceType implements MinorDeviceType {
  robot(1, 'Robot'),
  vehicle(2, 'Vehicle'),
  doll(3, 'Doll'),
  controller(4, 'Controller'),
  game(5, 'Game');

  @override
  final int number;
  @override
  final String name;

  const ToyMinorDeviceType(this.number, this.name);
}

class HealthDeviceType extends DeviceClass<HealthMinorDeviceType> {
  const HealthDeviceType({required super.minorClass}) : super(name: 'Health');

  factory HealthDeviceType.fromCod(int minorDeviceTypeNumber) {
    return HealthDeviceType(
      minorClass: getMinorDeviceClass(
        number: minorDeviceTypeNumber,
        values: HealthMinorDeviceType.values,
      ),
    );
  }
}

enum HealthMinorDeviceType implements MinorDeviceType {
  undefined(0, 'Undefined'),
  bloodPressureMonitor(1, 'Blood Pressure Monitor'),
  thermometer(2, 'Thermometer'),
  weighingScale(3, 'Weighing Scale'),
  glucoseMeter(4, 'Glucose Meter'),
  pulseOximeter(5, 'Pulse Oximeter'),
  heartRateMonitor(6, 'Heart/Pulse Rate Monitor'),
  healthDataDisplay(7, 'Health Data Display'),
  stepCounter(8, 'Step Counter'),
  bodyCompositionAnalyzer(9, 'Body Composition Analyzer'),
  peakFlowMonitor(10, 'Peak Flow Monitor'),
  medicationMonitor(11, 'Medication Monitor'),
  kneeProsthesis(12, 'Knee Prosthesis'),
  ankleProsthesis(13, 'Ankle Prosthesis'),
  genericHealthManager(14, 'Generic Health Manager'),
  personalMobilityDevice(15, 'Personal Mobility Device');

  @override
  final int number;
  @override
  final String name;

  const HealthMinorDeviceType(this.number, this.name);
}
