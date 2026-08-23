class DeviceConfig {
  final String deviceID;
  final String name;
  final String firmware;
  final String ip;
  final String mac;
  final int relayCount;
  final List<String> relayNames;
  final bool hasTankSensor;
  final bool hasVoltageSensor;
  final List<bool> relayStates;
  final double tankLevel;
  final double voltage;

  DeviceConfig({
    this.deviceID = '',
    this.name = 'MORAD_TK Device',
    this.firmware = '2.0.0',
    this.ip = '',
    this.mac = '',
    this.relayCount = 0,
    this.relayNames = const [],
    this.hasTankSensor = false,
    this.hasVoltageSensor = false,
    this.relayStates = const [],
    this.tankLevel = 0.0,
    this.voltage = 0.0,
  });

  // نسخة محدثة من الكائن
  DeviceConfig copyWith({
    String? deviceID,
    String? name,
    String? firmware,
    String? ip,
    String? mac,
    int? relayCount,
    List<String>? relayNames,
    bool? hasTankSensor,
    bool? hasVoltageSensor,
    List<bool>? relayStates,
    double? tankLevel,
    double? voltage,
  }) {
    return DeviceConfig(
      deviceID: deviceID ?? this.deviceID,
      name: name ?? this.name,
      firmware: firmware ?? this.firmware,
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      relayCount: relayCount ?? this.relayCount,
      relayNames: relayNames ?? this.relayNames,
      hasTankSensor: hasTankSensor ?? this.hasTankSensor,
      hasVoltageSensor: hasVoltageSensor ?? this.hasVoltageSensor,
      relayStates: relayStates ?? this.relayStates,
      tankLevel: tankLevel ?? this.tankLevel,
      voltage: voltage ?? this.voltage,
    );
  }
}