import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';

class VocabularyCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final Color? accentColor;

  const VocabularyCard({
    super.key,
    required this.vocabulary,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vocabulary.word,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vocabulary.meaning,
              style: const TextStyle(fontSize: 16),
            ),
            if (vocabulary.pronunciation != null &&
                vocabulary.pronunciation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                vocabulary.pronunciation!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (vocabulary.example != null &&
                vocabulary.example!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                vocabulary.example!,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
