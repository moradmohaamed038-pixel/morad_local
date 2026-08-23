import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/device_model.dart';
import 'services/websocket_service.dart';
import 'services/discovery_service.dart';
import 'widgets/relay_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        title: 'MORAD Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  final WebSocketService ws = WebSocketService();
  DeviceConfig? config;
  bool isConnected = false;
  String errorMessage = '';
  bool isLoading = false;
  String currentIP = '192.168.4.1';

  AppState() {
    ws.onDeviceConfig.listen((newConfig) {
      config = newConfig;
      isLoading = false;
      errorMessage = '';
      notifyListeners();
    });

    ws.onStatusUpdate.listen((updatedConfig) {
      // تحديث الحالة فقط (مع الحفاظ على الأسماء)
      if (config != null) {
        config = config!.copyWith(
          relayStates: updatedConfig.relayStates,
          tankLevel: updatedConfig.tankLevel,
          voltage: updatedConfig.voltage,
        );
        notifyListeners();
      } else {
        config = updatedConfig;
        notifyListeners();
      }
    });

    ws.onConnectionChange.listen((connected) {
      isConnected = connected;
      if (!connected && errorMessage.isEmpty) {
        errorMessage = 'غير متصل بالجهاز';
      }
      isLoading = false;
      notifyListeners();
    });

    ws.onError.listen((error) {
      errorMessage = error;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    // محاولة اكتشاف تلقائي
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final discoveredIP = await DiscoveryService.discoverDevice();
    if (discoveredIP != null) {
      currentIP = discoveredIP;
      ws.connect(currentIP);
    } else {
      // استخدام IP الافتراضي
      ws.connect(currentIP);
    }
  }

  void connectToIP(String ip) {
    currentIP = ip;
    isLoading = true;
    errorMessage = '';
    notifyListeners();
    ws.connect(ip);
  }

  void toggleRelay(int id, bool isOn) {
    ws.toggleRelay(id, isOn);
  }

  void refreshStatus() {
    if (isConnected) {
      ws.getStatus();
    }
  }

  void disconnect() {
    ws.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    ws.dispose();
    super.dispose();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎛️ MORAD Controller'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              appState.isConnected ? Icons.wifi : Icons.wifi_off,
              color: appState.isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!appState.isConnected) {
                _showConnectDialog(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: appState.isConnected ? appState.refreshStatus : null,
          ),
        ],
      ),
      body: _buildBody(context, appState),
    );
  }

  Widget _buildBody(BuildContext context, AppState appState) {
    if (appState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري البحث عن الجهاز...'),
          ],
        ),
      );
    }

    if (appState.errorMessage.isNotEmpty && appState.config == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              appState.errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showConnectDialog(context),
              icon: const Icon(Icons.wifi),
              label: const Text('محاولة الاتصال يدوياً'),
            ),
          ],
        ),
      );
    }

    if (appState.config == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل البيانات...'),
          ],
        ),
      );
    }

    final config = appState.config!;
    final relayCount = config.relayCount > 0 ? config.relayCount : 12;
    final relayNames = config.relayNames.length == relayCount
        ? config.relayNames
        : List.generate(relayCount, (i) => 'R${i + 1}');
    final relayStates = config.relayStates.length == relayCount
        ? config.relayStates
        : List.filled(relayCount, false);

    return RefreshIndicator(
      onRefresh: () async {
        appState.refreshStatus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الجهاز
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          appState.isConnected ? Icons.wifi : Icons.wifi_off,
                          color: appState.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appState.isConnected ? '🟢 متصل' : '🔴 غير متصل',
                          style: TextStyle(
                            color: appState.isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '📱 ${config.deviceID}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      config.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '📍 ${config.ip.isNotEmpty ? config.ip : appState.currentIP}:8080',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (config.mac.isNotEmpty)
                      Text(
                        '🔗 ${config.mac}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // المستشعرات
            if (config.hasTankSensor || config.hasVoltageSensor)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 قراءات المستشعرات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (config.hasTankSensor)
                            _buildSensorCard(
                              title: 'مستوى الخزان',
                              value: '${config.tankLevel.toInt()}%',
                              icon: Icons.water_drop,
                              color: Colors.blue,
                            ),
                          if (config.hasVoltageSensor)
                            _buildSensorCard(
                              title: 'الجهد',
                              value: '${config.voltage.toStringAsFixed(1)}V',
                              icon: Icons.flash_on,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // الريليهات
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 التحكم في الريليهات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${relayCount} ريليه',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: relayCount,
                      itemBuilder: (context, index) {
                        final id = index + 1;
                        final name = index < relayNames.length ? relayNames[index] : 'R$id';
                        final isOn = index < relayStates.length ? relayStates[index] : false;

                        return RelayButton(
                          id: id,
                          name: name,
                          isOn: isOn,
                          onToggle: () {
                            appState.toggleRelay(id, !isOn);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context) {
    final TextEditingController ipController = TextEditingController(text: '192.168.4.1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الاتصال بالجهاز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل عنوان IP للجهاز:'),
            const SizedBox(height: 8),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: 192.168.4.1',
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'تأكد من اتصال هاتفك بشبكة Wi-Fi الخاصة بالجهاز',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.connectToIP(ip);
                Navigator.pop(context);
              }
            },
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }
}