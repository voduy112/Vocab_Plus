import 'package:flutter/material.dart';

class PronunciationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int currentExercise;
  final String deckName;
  final VoidCallback onBack;
  final VoidCallback? onDownloadTap;

  const PronunciationAppBar({
    super.key,
    required this.currentExercise,
    required this.deckName,
    required this.onBack,
    this.onDownloadTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: onBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deckName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: onDownloadTap != null
          ? [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: onDownloadTap,
                tooltip: 'Tải âm thanh Voice Coach',
              ),
            ]
          : null,
    );
  }
}
