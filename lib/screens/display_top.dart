import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_ajakuma/services/temperature_service.dart';
import 'package:flutter_application_ajakuma/services/mqtt_service.dart';
import 'package:flutter_application_ajakuma/constants/app_constants.dart';
import 'package:flutter_application_ajakuma/widgets/animated_kuma.dart';


final logger = Logger();

class TempDisplayScreen extends StatefulWidget {
  const TempDisplayScreen({super.key});

  @override
  State<TempDisplayScreen> createState() => _TempDisplayScreenState();
}

class _TempDisplayScreenState extends State<TempDisplayScreen> with TickerProviderStateMixin {
  String temperatureText = "読み込み中...";
  double? temperatureValue;
  bool isLoading = false;
  bool isDancing = false;
  bool isStoping = false;

  late final MqttService mqttService;
  StreamSubscription<String>? _tempSub;

  final TemperatureService service = TemperatureService(kDeviceIpAddress);

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(
      broker: kMqttBroker,
      port: kMqttWsPort,
      username: kMqttUser,
      password: kMqttPassword,
    );
    connectToMqtt();
  }

  Future<void> connectToMqtt() async {
    await mqttService.connect();

    // 温度トピックを購読
    final stream = mqttService.subscribe('temperature/topic');
    _tempSub = stream.listen((message) {
      final temp = double.tryParse(message);
      if (temp != null) {
        setState(() {
          temperatureValue = temp;
          temperatureText = "${temp.toStringAsFixed(1)} ℃";
          isDancing = temp >= 28 && !isStoping;
          if(temp < 28){
            isStoping = false;
          }
        });
      } else {
        logger.w("数値変換できない温度: $message");
      }
    });  
  }

  void requestTemperature() {
    logger.d("依頼発生");
    // if (isLoading) return;
    // setState(() => isLoading = true);
    mqttService.publish('request/temperature', 'get');
    setState(() {
      temperatureText = "リクエスト中...";
    });
  }

  void sendStopSignal() {
    mqttService.publish('cmd/ajakuma', 'stop');
    setState(() {
      isStoping = true;
      temperatureText = "すとっぷ中";
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isStoping = false;
        isDancing = false;
      });
    });
  }

  // Future<void> fetchTemperature() async {
  //   if (isLoading) return;
  //   setState(() => isLoading = true);

  //   try {
  //     final temp = await service.fetchTemperature();
  //     setState(() {
  //       temperatureValue = temp;
  //       temperatureText = temp != null ? "${temp.toStringAsFixed(1)} ℃" : "取得失敗";
  //       isDancing = (temperatureValue ?? 0) >= 28;
  //     });
  //   } catch (e) {
  //     setState(() => temperatureText = "通信失敗: $e");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  // Future<void> fetchStopMotion() async {
  //   if (isStoping) return;
  //   setState(() => isStoping = true);

  //   try {
  //     await service.sendStopSignal();
  //     setState(() {
  //       isDancing = false;
  //       temperatureText = "すとっぷ中";
  //     });
  //   } catch (e) {
  //     setState(() => temperatureText = "通信失敗: $e");
  //   } finally {
  //     setState(() => isStoping = false);
  //   }
  // }

  @override
  void dispose() {
    _tempSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoImage = Image.asset(
      'assets/images/AjaKuma_logo.png',
      width: 500,
      height: 200,
      fit: BoxFit.contain
    );

    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: AppBar(
          backgroundColor: Colors.amber[50],
          elevation: 0,
          flexibleSpace: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: logoImage,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = MediaQuery.of(context).size.width;
          double cardWidth = screenWidth * 0.85; // 画面の85%を使用          
          return Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "現在の温度",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Text(
                          temperatureText, 
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                        )
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 5,
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth * 0.5,
                    child: TemperatureImage(isDancing: isDancing),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDancing ? "だんしんぐ！" : "すりーぴんぐ…",
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Expanded(
                    //   child: ElevatedButton(
                    //     onPressed: requestTemperature,
                    //     style: ElevatedButton.styleFrom(
                    //       padding: const EdgeInsets.symmetric(vertical: 16),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8))
                    //     ),
                    //     child: const Text("更新"),
                    //     // child: isLoading
                    //     //   ? const SizedBox(
                    //     //       width: 16,
                    //     //       height: 16,
                    //     //       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    //     //     )
                    //     //   : const Text("更新"),
                    //   ),
                    // ),
                    const SizedBox(width: 8),
                    if (isDancing) ...[
                      Expanded(child: 
                        ElevatedButton(
                          onPressed: isStoping ? null : sendStopSignal,
                          child: isStoping
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2
                                  ),
                                )
                              : const Text("止める"),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO 音楽変更しょり
                          setState(() {
                            temperatureText = "音楽へんこう！";
                          });
                        }, 
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("おんがくへんこう")
                        ),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}