import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';

class DeckRow extends StatelessWidget {
  final Desk desk;
  final Map<String, dynamic> stats;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DeckRow({
    super.key,
    required this.desk,
    required this.stats,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final int needReview = stats['needReview'] as int;
    final double progress = stats['progress'] as double;
    final int total = stats['total'] as int;
    final int learned = stats['learned'] as int;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desk.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$learned/$total words',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                needReview.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: needReview > 0 ? Colors.orange[600] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight:
                      needReview > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
