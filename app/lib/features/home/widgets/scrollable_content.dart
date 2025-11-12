import 'package:flutter/material.dart';
import 'feature_grid.dart';
import 'study_schedule_section.dart';

// Widget nội dung scrollable
class ScrollableContent extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const ScrollableContent({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContentCard(start: start, end: end),
    );
  }
}

// Widget Content Card
class ContentCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const ContentCard({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid chức năng
            const FeatureGrid(),
            // Phần lịch học
            StudyScheduleSection(start: start, end: end),
          ],
        ),
      ),
    );
  }
}
