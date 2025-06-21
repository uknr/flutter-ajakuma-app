import 'package:flutter/material.dart';
import 'screens/display_top.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TempApp());
}

class TempApp extends StatelessWidget {
  const TempApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '温度表示アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.kosugiMaruTextTheme(),
      ),
      home: const TempDisplayScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}