import 'package:flutter/material.dart';
import 'due_heat_map.dart';

// Widget phần lịch học
class StudyScheduleSection extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const StudyScheduleSection({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Lịch học',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        DueHeatMap(start: start, end: end),
        const SizedBox(height: 500),
      ],
    );
  }
}
