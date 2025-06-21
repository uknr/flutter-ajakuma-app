import 'package:http/http.dart' as http;

class TemperatureService {
  final String ipAddress;

  TemperatureService(this.ipAddress);

  Future<double?> fetchTemperature() async {
    final response = await http.get(Uri.parse(ipAddress));
    if (response.statusCode == 200) {
      return double.tryParse(response.body.trim());
    } else {
      throw Exception('温度取得エラー: ${response.statusCode}');
    }
  }

  Future<void> sendStopSignal() async {
    final response = await http.get(Uri.parse('$ipAddress/stop'));
    if (response.statusCode != 200) {
      throw Exception('停止通信エラー: ${response.statusCode}');
    }
  }
}