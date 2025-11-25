import 'package:flutter/material.dart';

import '../../../core/models/pronunciation_result.dart';

class OverallScoreCard extends StatelessWidget {
  final PronunciationResult result;
  final Color Function(double score) colorResolver;

  const OverallScoreCard({
    super.key,
    required this.result,
    required this.colorResolver,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColor = colorResolver(result.overall);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColor,
              gradientColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Điểm tổng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${result.overall.toStringAsFixed(1)}/100',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ScoreMetricItem(label: 'Độ chính xác', value: result.accuracy),
                ScoreMetricItem(label: 'Độ trôi chảy', value: result.fluency),
                ScoreMetricItem(
                  label: 'Hoàn chỉnh',
                  value: result.completeness,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreMetricItem extends StatelessWidget {
  final String label;
  final double value;

  const ScoreMetricItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
