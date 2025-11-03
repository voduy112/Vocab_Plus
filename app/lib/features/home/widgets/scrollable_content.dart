import 'package:flutter/material.dart';
import 'feature_grid.dart';
import 'study_schedule_section.dart';

// Widget nội dung scrollable
class ScrollableContent extends StatelessWidget {
  final ScrollController scrollController;
  final DateTime start;
  final DateTime end;

  const ScrollableContent({
    super.key,
    required this.scrollController,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -60,
      left: 0,
      right: 0,
      bottom: 0,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Khoảng trống để hiển thị header ban đầu
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            // Nội dung scrollable
            ContentCard(start: start, end: end),
          ],
        ),
      ),
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
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
      ),
    );
  }
}
