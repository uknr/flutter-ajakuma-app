import 'package:flutter_application_ajakuma/screens/display_top.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttService {
  final String broker;
  final int port;
  final String username;
  final String password;

  late final MqttBrowserClient _client;

  MqttService({
    required this.broker,
    required this.port,
    required this.username,
    required this.password,
  }) {
    logger.d('wss://$broker');
    _client = MqttBrowserClient('wss://$broker/mqtt', 'flutter_client');
    _client.port = port;
    // _client.secure = true;
    _client.keepAlivePeriod = 20;
    _client.logging(on: false);

    _client.onDisconnected = () => logger.d('🔌 MQTT disconnected');
  }

  Future<void> connect() async {
    final connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .startClean();
    _client.connectionMessage = connMess;
    await _client.connect();
    logger.d('✅ MQTT connected');
  }

  /// トピック購読。戻り値はストリーム (文字列)
  Stream<String> subscribe(String topic) {
    _client.subscribe(topic, MqttQos.atMostOnce);
    return _client.updates!
        .where((event) => event.isNotEmpty && event[0].topic == topic)
        .map((event) {
          final payload = event[0].payload as MqttPublishMessage;
          final bytes = payload.payload.message;
          return String.fromCharCodes(bytes); // ←ここ！
        });
  }

  void publish(String topic, String payload) {
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
