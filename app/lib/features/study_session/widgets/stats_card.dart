import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int totalVocabularies;
  final int learnedCount;
  final int reviewCount;
  final Color accentColor;

  const StatsCard({
    super.key,
    required this.totalVocabularies,
    required this.learnedCount,
    required this.reviewCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Tổng từ vựng',
            totalVocabularies.toString(),
            Icons.library_books,
            accentColor,
          ),
          _buildStatItem(
            'Đã học',
            learnedCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            'Cần ôn',
            reviewCount.toString(),
            Icons.refresh,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
