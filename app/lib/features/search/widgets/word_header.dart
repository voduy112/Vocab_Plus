import 'package:flutter/material.dart';
import '../../../data/dictionary/models.dart';
import 'sound_actions.dart';
import 'ipa_row.dart';

class WordHeader extends StatelessWidget {
  final WordEntry entry;
  const WordHeader({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.images.isNotEmpty && entry.images.first.local != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'lib/core/assets/dictionary/${entry.images.first.local!}',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        entry.word,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SoundActions(entry: entry),
                  ],
                ),
                const SizedBox(height: 4),
                IpaRow(entry: entry),
                if (entry.wordVi != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(entry.wordVi!,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[700])),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
