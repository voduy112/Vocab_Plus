import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';

class VocabularyCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const VocabularyCard({
    super.key,
    required this.vocabulary,
    required this.onTap,
    required this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      color: isSelected ? Colors.blue.shade50.withOpacity(0.5) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue.shade400,
                    width: 2,
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox khi ở selection mode
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onTap(),
                  activeColor: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
              ],
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
                        vocabulary
                            .frontExtra!['pronunciation']!.isNotEmpty) ...[
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
                    Text(
                      vocabulary.back,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
              // Divider giữa cột 2 và 3
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.grey[300],
              ),
              // Cột 3: Ngày tới hạn
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: _getDueDateColor(
                              vocabulary.srsDue ?? vocabulary.nextReview),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDueDate(
                                vocabulary.srsDue ?? vocabulary.nextReview),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getDueDateColor(
                                  vocabulary.srsDue ?? vocabulary.nextReview),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (vocabulary.srsDue != null ||
                        vocabulary.nextReview != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _getDueDateStatus(
                            vocabulary.srsDue ?? vocabulary.nextReview),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Icon 3 chấm ở cuối thẻ
              if (!isSelectionMode)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
        ),
      ),
    );
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Chưa có';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return 'Quá hạn';
    } else if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference < 7) {
      return '$difference ngày';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks tuần';
    } else {
      return '${due.day}/${due.month}';
    }
  }

  Color _getDueDateColor(DateTime? dueDate) {
    if (dueDate == null) return Colors.grey[600]!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return Colors.red[600]!; // Quá hạn - đỏ
    } else if (difference == 0) {
      return Colors.orange[600]!; // Hôm nay - cam
    } else if (difference <= 3) {
      return Colors.orange[500]!; // Sắp tới hạn - cam nhạt
    } else {
      return Colors.green[600]!; // Còn xa - xanh
    }
  }

  String _getDueDateStatus(DateTime? dueDate) {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return '${difference.abs()} ngày trước';
    } else if (difference == 0) {
      return 'Cần ôn tập';
    } else if (difference <= 3) {
      return 'Sắp tới hạn';
    } else {
      return 'Còn thời gian';
    }
  }
}
