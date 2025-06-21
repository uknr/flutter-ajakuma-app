import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TemperatureImage extends StatelessWidget {
  final bool isDancing;

  const TemperatureImage({super.key, required this.isDancing});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/images/ajakuma.png', width: 300, height: 300);
    return isDancing
        ? image.animate(onPlay: (controller) => controller.repeat()).rotate(duration: 600.ms)
        : image;
  }
}