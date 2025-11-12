// features/main/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/feature_grid.dart';
import '../widgets/study_schedule_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 15);
    final end = DateTime(now.year, now.month + 2, now.day);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const HomeHeader(),
            // Nội dung
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
