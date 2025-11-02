import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../repositories/vocabulary_repository.dart';

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
    final int total = stats['total'] as int;
    final int learned = stats['learned'] as int;
    // newCount will be computed asynchronously in the UI as: total - learned - minuteLearning
    final int dueCount = needReview;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  const SizedBox(height: 1),
                  Text(
                    '$total words',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<int>(
                      future: desk.id != null
                          ? VocabularyRepository().countMinuteLearning(desk.id!)
                          : Future.value(0),
                      builder: (context, snapshot) {
                        final minute = snapshot.hasData ? snapshot.data! : 0;
                        final newCount =
                            (total - learned - minute).clamp(0, total);
                        return Text(
                          newCount.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: desk.id != null
                          ? VocabularyRepository().countMinuteLearning(desk.id!)
                          : Future.value(0),
                      builder: (context, snapshot) {
                        final value = snapshot.hasData ? snapshot.data! : 0;
                        return Text(
                          value.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dueCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
