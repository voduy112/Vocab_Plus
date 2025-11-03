import 'package:flutter/material.dart';
import '../../../core/models/srs_choice.dart';

class ChoiceButtons extends StatelessWidget {
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final bool isVisible;

  const ChoiceButtons({
    super.key,
    required this.labels,
    required this.onChoiceSelected,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isVisible ? 1.0 : 0.0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _labelText(labels[SrsChoice.again] ?? ''),
              _labelText(labels[SrsChoice.hard] ?? ''),
              _labelText(labels[SrsChoice.good] ?? ''),
              _labelText(labels[SrsChoice.easy] ?? ''),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _pillButton(
                'Lại',
                () => onChoiceSelected(SrsChoice.again),
                backgroundColor: Colors.red.withOpacity(0.7),
              ),
              _pillButton(
                'Khó',
                () => onChoiceSelected(SrsChoice.hard),
                backgroundColor: Colors.orange.withOpacity(0.7),
              ),
              _pillButton(
                'Được',
                () => onChoiceSelected(SrsChoice.good),
                backgroundColor: Colors.blue.withOpacity(0.7),
              ),
              _pillButton(
                'Dễ',
                () => onChoiceSelected(SrsChoice.easy),
                backgroundColor: Colors.green.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelText(String text) {
    return SizedBox(
      width: 70,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _pillButton(String text, VoidCallback onPressed,
      {Color? backgroundColor}) {
    return SizedBox(
      width: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
