import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PronunciationConfetti extends StatelessWidget {
  const PronunciationConfetti({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: FractionallySizedBox(
          widthFactor: 1.1,
          heightFactor: 0.5,
          alignment: Alignment.topCenter,
          child: Lottie.asset(
            'lib/core/assets/splash/Confetti.json',
            repeat: false,
            fit: BoxFit.contain,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}


