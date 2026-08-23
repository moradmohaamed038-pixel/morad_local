import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import '../models/device_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool isConnected = false;

  final _deviceConfigController = StreamController<DeviceConfig>.broadcast();
  final _statusController = StreamController<DeviceConfig>.broadcast(); // نستخدم نفس النموذج للتحديثات
  final _connectionController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<DeviceConfig> get onDeviceConfig => _deviceConfigController.stream;
  Stream<DeviceConfig> get onStatusUpdate => _statusController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<String> get onError => _errorController.stream;

  void connect(String ip, {int port = 8080}) {
    try {
      final url = 'ws://$ip:$port';
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          isConnected = false;
          _connectionController.add(false);
        },
        onError: (error) {
          isConnected = false;
          _connectionController.add(false);
          _errorController.add('خطأ في الاتصال: $error');
        },
      );

      isConnected = true;
      _connectionController.add(true);

      // طلب الحالة فوراً
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isConnected) {
          getStatus();
        }
      });
    } catch (e) {
      isConnected = false;
      _connectionController.add(false);
      _errorController.add('فشل الاتصال: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final String messageStr = message is String ? message : message.toString();
      final Map<String, dynamic> json = jsonDecode(messageStr);

      // تحليل الرسالة إلى DeviceConfig
      final config = _parseDeviceConfig(json);
      _deviceConfigController.add(config);

      // إذا احتوت على حالة الريليهات أو المستشعرات، نعتبرها تحديثاً للحالة
      if (json.containsKey('relays') || json.containsKey('tankLevel') || json.containsKey('voltage')) {
        _statusController.add(config);
      }
    } catch (e) {
      _errorController.add('خطأ في معالجة الرسالة: $e');
    }
  }

  DeviceConfig _parseDeviceConfig(Map<String, dynamic> json) {
    // قراءة عدد الريليهات ومصفوفتها
    int relayCount = 0;
    List<String> relayNames = [];
    List<bool> relayStates = [];

    if (json.containsKey('relays') && json['relays'] is List) {
      final relaysArray = json['relays'] as List;
      relayCount = relaysArray.length;
      for (var relay in relaysArray) {
        if (relay is Map<String, dynamic>) {
          relayNames.add(relay['id']?.toString() ?? 'R${relayNames.length + 1}');
          relayStates.add(relay['isOn'] ?? false);
        } else {
          relayNames.add('R${relayNames.length + 1}');
          relayStates.add(false);
        }
      }
    } else {
      relayCount = json['relays'] is int ? json['relays'] : 0;
      for (int i = 1; i <= relayCount; i++) {
        relayNames.add('R$i');
        relayStates.add(false);
      }
    }

    // استشعار الخزان والجهد
    bool hasTank = json.containsKey('tankLevel');
    bool hasVoltage = json.containsKey('voltage');
    double tankLevel = (json['tankLevel'] ?? 0.0).toDouble();
    double voltage = (json['voltage'] ?? 0.0).toDouble();

    return DeviceConfig(
      deviceID: json['deviceID']?.toString() ?? 'UNKNOWN',
      name: json['name']?.toString() ?? 'MORAD_TK Device',
      firmware: json['firmware']?.toString() ?? '2.0.0',
      ip: json['ip']?.toString() ?? '',
      mac: json['mac']?.toString() ?? '',
      relayCount: relayCount,
      relayNames: relayNames,
      hasTankSensor: hasTank,
      hasVoltageSensor: hasVoltage,
      relayStates: relayStates,
      tankLevel: tankLevel,
      voltage: voltage,
    );
  }

  void sendCommand(String action, {int? relayId, bool? value, int? minutes}) {
    if (_channel == null || !isConnected) {
      _errorController.add('الجهاز غير متصل');
      return;
    }

    try {
      final Map<String, dynamic> command = {
        'action': action,
      };
      if (relayId != null) command['relayId'] = relayId;
      if (value != null) command['value'] = value;
      if (minutes != null) command['minutes'] = minutes;

      _channel!.sink.add(jsonEncode(command));
    } catch (e) {
      _errorController.add('فشل إرسال الأمر: $e');
    }
  }

  void toggleRelay(int relayId, bool isOn) {
    sendCommand('toggleRelay', relayId: relayId, value: isOn);
  }

  void setTimer(int relayId, int minutes) {
    sendCommand('setTimer', relayId: relayId, minutes: minutes);
  }

  void getStatus() {
    sendCommand('getStatus');
  }

  void disconnect() {
    try {
      _channel?.sink.close(status.goingAway);
    } catch (_) {}
    _channel = null;
    isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _deviceConfigController.close();
    _statusController.close();
    _connectionController.close();
    _errorController.close();
  }
}