import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class ChoiceButtons extends StatelessWidget {
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;

  const ChoiceButtons({
    super.key,
    required this.labels,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            _pillButton('Lại', () => onChoiceSelected(SrsChoice.again)),
            _pillButton('Khó', () => onChoiceSelected(SrsChoice.hard)),
            _pillButton('Được', () => onChoiceSelected(SrsChoice.good)),
            _pillButton('Dễ', () => onChoiceSelected(SrsChoice.easy)),
          ],
        ),
      ],
    );
  }

  Widget _labelText(String text) {
    return SizedBox(
      width: 70,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _pillButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }
}
