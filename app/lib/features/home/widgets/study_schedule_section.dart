import 'package:flutter/material.dart';
import 'due_heat_map.dart';

// Widget phần lịch học
class StudyScheduleSection extends StatefulWidget {
  final DateTime start;
  final DateTime end;

  const StudyScheduleSection({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  State<StudyScheduleSection> createState() => _StudyScheduleSectionState();
}

class _StudyScheduleSectionState extends State<StudyScheduleSection> {
  int _refreshKey = 0;

  void refresh() {
    // Invalidate cache and trigger rebuild by changing key
    DueHeatMap.invalidateAllCache();
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: DueHeatMap(
            key: ValueKey(_refreshKey),
            start: widget.start,
            end: widget.end,
          ),
        ),
      ],
    );
  }
}
