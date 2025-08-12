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
  bool isWarning = false;

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
        // 温度に応じてステータスを更新
        setState(() {
          temperatureValue = temp;
          // 温度表示
          temperatureText = "${temp.toStringAsFixed(1)} ℃";
          // 28度以上かつ、ストップ命令がない場合true
          isDancing = temp >= 28 && !isStoping;
          // 26度以上かつ28度未満かつ、ストップ命令がない場合true
          isWarning = 26 <= temp && temp < 28 && !isStoping;
          // 一度ストップしてから再度28度を下回るまで、ストップ命令はリセットしない
          if(temp < 28){
            isStoping = false;
          }
        });
      } else {
        logger.w("数値変換できない温度: $message");
      }
    });  
  }

  // [あじゃくまくんイメチェン機能]背景色を温度によって変える
  // TODO:初回は固定でconst Color.fromARGB(255, 255, 220, 48)を返すようにしてください
  Color getBackgroundColor() {
    if (!isDancing && !isWarning) {
      return const Color.fromARGB(255, 222, 235, 240);
    } else if (isWarning) {
      return const Color.fromARGB(255, 255, 220, 48);
    } else {
      return const Color.fromARGB(255, 240, 118, 18);
    }
  }


  // [あじゃくまくんイメチェン機能]背景色を温度によって変える
  // TODO:初回はisWarningによる文字の変更はないでもいいしあるでもいい
  String getComment() {
    if (!isDancing && !isWarning) {
      return '／ すりーぴんぐ… ＼';
    } else if (isWarning) {
      return '／ そわそわ… ＼';
    } else {
      return '／ だんしんぐ！ ＼';
    }
  }

  // 温度取得命令(使ってない気がする)
  void requestTemperature() {
    logger.d("依頼発生");
    // if (isLoading) return;
    // setState(() => isLoading = true);
    mqttService.publish('request/temperature', 'get');
    setState(() {
      temperatureText = "リクエスト中...";
    });
  }

  // ストップ命令
  void sendStopSignal() {
    mqttService.publish('cmd/ajakuma', 'stop');
    setState(() {
      isStoping = true;
      temperatureText = "すとっぷ中";
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isDancing = false;
      });
    });
  }

  @override
  void dispose() {
    _tempSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ロゴ設定。28度を超えたら背景色が濃くなるため、白文字ロゴにする
    dynamic imagPath = isDancing ? 'assets/images/AjaKuma_logo_dancing.png' : 'assets/images/AjaKuma_logo.png';
    final logoImage = Image.asset(
      imagPath,
      width: 500,
      height: 200,
      fit: BoxFit.contain
    );

    return Scaffold(
      backgroundColor: getBackgroundColor(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: AppBar(
          backgroundColor:getBackgroundColor(),
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
                    child: TemperatureImage(isDancing: isDancing,isWarning: isWarning),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getComment(),
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
                            style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            backgroundColor: const Color.fromARGB(255, 184, 144, 255),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isStoping
                              ? const SizedBox(
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2
                                  ),
                                )
                              : const Text("とめる",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                ),
                              ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          String selectedMusic = 'mori_kuma'; // 初期選択（森のくまさん）
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text("音楽を選んでね"),
                                content: StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RadioListTile(
                                          title: const Text("森のくまさん"),
                                          value: 'mori_kuma',
                                          groupValue: selectedMusic,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedMusic = value!;
                                            });
                                          },
                                        ),
                                        RadioListTile(
                                          title: const Text("あつ森のテーマ"),
                                          value: 'atsumori',
                                          groupValue: selectedMusic,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedMusic = value!;
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("キャンセル"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  ElevatedButton(
                                    child: const Text("へんこう"),
                                    onPressed: () {
                                      // NodeMCU に音楽変更コマンド送信
                                      mqttService.publish('cmd/ajakuma', 'music:$selectedMusic');

                                      Navigator.of(context).pop(); // ダイアログ閉じる
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("音楽を変更しました: $selectedMusic")),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }, 
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          backgroundColor: const Color.fromARGB(255, 184, 144, 255),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("おんがくへんこう",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                              ),
                          ),
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