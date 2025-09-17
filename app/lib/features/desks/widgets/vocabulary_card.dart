import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';

class VocabularyCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const VocabularyCard({
    super.key,
    required this.vocabulary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.bookmark_outline),
        title: Text(
          vocabulary.word,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vocabulary.meaning),
            if (vocabulary.pronunciation != null) ...[
              const SizedBox(height: 2),
              Text(
                vocabulary.pronunciation!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (vocabulary.example != null) ...[
              const SizedBox(height: 4),
              Text(
                vocabulary.example!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
