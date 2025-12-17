import 'package:flutter/material.dart';

class PronunciationNavigationBar extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final bool isLast;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onSubmit;

  const PronunciationNavigationBar({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.isLast,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    this.onSubmit,
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
            child: isLast
                ? TextButton.icon(
                    onPressed:
                        (onSubmit != null && !isSubmitting) ? onSubmit : null,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Hoàn thành'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerRight,
                    ),
                  )
                : TextButton.icon(
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
