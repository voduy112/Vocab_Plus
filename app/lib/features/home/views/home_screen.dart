// features/main/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/scrollable_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 15);
    final end = DateTime(now.year, now.month + 2, now.day);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Lớp dưới: Header (có hiệu ứng khi scroll)
            HomeHeader(scrollController: _scrollController),
            // Lớp giữa: Nội dung có thể scroll (chồng lên header)
            ScrollableContent(
              scrollController: _scrollController,
              start: start,
              end: end,
            ),
            // Lớp trên cùng: Notification icon (không bị che phủ)
            Positioned(
              top: 20,
              right: 16,
              child: AnimatedNotificationIcon(
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
