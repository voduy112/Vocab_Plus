import 'package:flutter/material.dart';

class PronunciationNavigationBar extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PronunciationNavigationBar({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: hasPrevious ? onPrevious : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextButton.icon(
              onPressed: hasNext ? onNext : null,
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              label: const Text('Next'),
              style: TextButton.styleFrom(
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


