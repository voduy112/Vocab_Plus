// core/widgets/tab_page_view.dart
import 'package:flutter/material.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/desks/views/desk_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/search/views/search_screen.dart';

class TabPageView extends StatefulWidget {
  final int currentIndex;
  final Function(int) onPageChanged;

  const TabPageView({
    Key? key,
    required this.currentIndex,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<TabPageView> createState() => _TabPageViewState();
}

class _TabPageViewState extends State<TabPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(TabPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _pageController.jumpToPage(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: widget.onPageChanged,
      children: const [
        HomeScreen(),
        DesksScreen(),
        SearchScreen(),
        ProfileScreen(),
      ],
    );
  }
}
