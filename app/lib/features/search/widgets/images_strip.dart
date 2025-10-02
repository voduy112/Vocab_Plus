import 'package:flutter/material.dart';
import '../../../data/dictionary/models.dart';

class ImagesStrip extends StatelessWidget {
  final WordEntry entry;
  const ImagesStrip({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    if (entry.images.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: entry.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final im = entry.images[i];
          final local = im.local;
          if (local == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/core/assets/dictionary/$local',
              width: 120,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 80,
                color: Colors.grey.shade200,
              ),
            ),
          );
        },
      ),
    );
  }
}
