import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int reviewCount;
  final int minuteLearningCount;
  final int newCount;
  // final Color accentColor;

  const StatsCard({
    super.key,
    required this.reviewCount,
    required this.minuteLearningCount,
    required this.newCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Mới',
            newCount.toString(),
            Icons.fiber_new,
            Colors.blue,
          ),
          _buildStatItem(
            'Học',
            minuteLearningCount.toString(),
            Icons.timer,
            Colors.cyan,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
