import 'package:flutter/material.dart';

class FeaturedCard extends StatelessWidget {
  final int totalWords;
  final int totalLearned;
  final int totalNewWords;
  final int totalDue;

  const FeaturedCard({
    super.key,
    required this.totalWords,
    required this.totalLearned,
    required this.totalNewWords,
    required this.totalDue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.pink.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_books,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Overview',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.book,
                  label: 'Total Words',
                  value: totalWords.toString(),
                  color: Colors.white70,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Learned',
                  value: totalLearned.toString(),
                  color: Colors.green[200]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.new_releases,
                  label: 'New Words',
                  value: totalNewWords.toString(),
                  color: Colors.blue[200]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Need Review',
                  value: totalDue.toString(),
                  color: Colors.orange[200]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
