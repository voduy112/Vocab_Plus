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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột 1: Front (từ vựng)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocabulary.front,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Pronunciation nếu có
                    if (vocabulary.frontExtra != null &&
                        vocabulary.frontExtra!.containsKey('pronunciation') &&
                        vocabulary.frontExtra!['pronunciation']!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vocabulary.frontExtra!['pronunciation']!,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Divider giữa 2 cột
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.grey[300],
              ),
              // Cột 2: Back (nghĩa)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vocabulary.back,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey[600],
                          ),
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
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Xóa'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Example nếu có
                    if (vocabulary.frontExtra != null &&
                        vocabulary.frontExtra!.containsKey('example') &&
                        vocabulary.frontExtra!['example']!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vocabulary.frontExtra!['example']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
