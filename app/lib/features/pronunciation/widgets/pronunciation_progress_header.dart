import 'package:flutter/material.dart';

class PronunciationProgressHeader extends StatelessWidget {
  final int currentExercise;
  final int totalExercises;

  const PronunciationProgressHeader({
    super.key,
    required this.currentExercise,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = totalExercises == 0 ? 1 : totalExercises;
    final progress = currentExercise / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$currentExercise/$total',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
