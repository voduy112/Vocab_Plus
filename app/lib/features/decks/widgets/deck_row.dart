import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../repositories/vocabulary_repository.dart';

class DeckRow extends StatefulWidget {
  final Deck desk;
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
  State<DeckRow> createState() => _DeckRowState();
}

class _DeckRowState extends State<DeckRow> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final int needReview = widget.stats['needReview'] as int;
    final int total = widget.stats['total'] as int;
    final int learned = widget.stats['learned'] as int;
    final int dueCount = needReview;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.blue.withOpacity(0.08),
        highlightColor: Colors.blue.withOpacity(0.04),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: _isPressed ? 0.98 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                left: widget.desk.isFavorite
                    ? BorderSide(color: Colors.pink!, width: 4)
                    : BorderSide.none,
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
                        widget.desk.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$total từ',
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
                          future: widget.desk.id != null
                              ? VocabularyRepository()
                                  .countMinuteLearning(widget.desk.id!)
                              : Future.value(0),
                          builder: (context, snapshot) {
                            final minute =
                                snapshot.hasData ? snapshot.data! : 0;
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
                          future: widget.desk.id != null
                              ? VocabularyRepository()
                                  .countMinuteLearning(widget.desk.id!)
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
        ),
      ),
    );
  }
}
