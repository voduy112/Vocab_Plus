import 'package:flutter/material.dart';
import '../../../data/dictionary/models.dart';

class IpaRow extends StatelessWidget {
  final WordEntry entry;
  const IpaRow({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final sounds = entry.sounds ?? const <WordSound>[];
    if (sounds.isEmpty) return const SizedBox.shrink();

    String? findIpaByTag(String tag) {
      final upper = tag.toUpperCase();
      final tagged = sounds.where((s) => (s.ipa != null &&
          s.tags.any((t) => t.toString().toUpperCase() == upper)));
      if (tagged.isNotEmpty) return tagged.first.ipa;
      final byName = sounds.where((s) =>
          (s.ipa != null) &&
          ((s.audio ?? '').toLowerCase().contains(upper.toLowerCase())));
      if (byName.isNotEmpty) return byName.first.ipa;
      return null;
    }

    final ipaUS = findIpaByTag('US');
    final ipaUK = findIpaByTag('UK');
    final fallback = (ipaUS == null && ipaUK == null)
        ? (sounds
            .firstWhere((s) => s.ipa != null,
                orElse: () => WordSound(
                    enpr: null, ipa: null, audio: null, tags: const []))
            .ipa)
        : null;

    final chips = <Widget>[];
    if (ipaUS != null) {
      chips.add(_IpaChip(label: 'US', ipa: ipaUS));
    }
    if (ipaUK != null) {
      chips.add(_IpaChip(label: 'UK', ipa: ipaUK));
    }
    if (chips.isEmpty && fallback != null) {
      chips.add(_IpaChip(label: 'IPA', ipa: fallback));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }
}

class _IpaChip extends StatelessWidget {
  final String label;
  final String ipa;
  const _IpaChip({required this.label, required this.ipa});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(ipa,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
