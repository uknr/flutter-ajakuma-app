
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_ajakuma/services/temperature_service.dart';
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

  final TemperatureService service = TemperatureService(kDeviceIpAddress);

  @override
  void initState() {
    super.initState();
    fetchTemperature();
  }

  Future<void> fetchTemperature() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final temp = await service.fetchTemperature();
      setState(() {
        temperatureValue = temp;
        temperatureText = temp != null ? "${temp.toStringAsFixed(1)} ℃" : "取得失敗";
        isDancing = (temperatureValue ?? 0) >= 28;
      });
    } catch (e) {
      setState(() => temperatureText = "通信失敗: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchStopMotion() async {
    if (isStoping) return;
    setState(() => isStoping = true);

    try {
      await service.sendStopSignal();
      setState(() {
        isDancing = false;
        temperatureText = "すとっぷ中";
      });
    } catch (e) {
      setState(() => temperatureText = "通信失敗: $e");
    } finally {
      setState(() => isStoping = false);
    }
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
                      Text(temperatureText, style: const TextStyle(
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : fetchTemperature,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8))
                        ),
                        child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("更新"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDancing) ...[
                      Expanded(child: 
                        ElevatedButton(
                          onPressed: isStoping ? null : fetchStopMotion,
                          child: isStoping
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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