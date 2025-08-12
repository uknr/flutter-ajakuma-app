import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TemperatureImage extends StatelessWidget {
  final bool isDancing;
  final bool isWarning;

  const TemperatureImage({
    super.key, 
    required this.isDancing,
    required this.isWarning
  });

  // くまちゃんを温度によって変える
  String getBackgroundColor() {
    if (!isDancing && !isWarning) {
      return 'assets/images/ajakuma.png';
    } else if (isWarning) {
      return 'assets/images/ajakuma_warning.png';
    } else {
      return 'assets/images/ajakuma_dancing.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(getBackgroundColor(), width: 300, height: 300);
    return isDancing
        ? image.animate(onPlay: (controller) => controller.repeat()).rotate(duration: 600.ms)
        : image;
  }
}