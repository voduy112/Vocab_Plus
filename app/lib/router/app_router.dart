// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/desks/views/desk_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/search/views/search_screen.dart';
import '../../features/search/views/word_detail_screen.dart';
import '../../data/dictionary/models.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/widgets/tab_page_view.dart';
import '../../core/widgets/custom_bottom_nav.dart';
import '../../core/widgets/ai_chat_button.dart';

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation:
        '/tabs/main', // Có thể thay đổi thành '/tabs/desks' hoặc '/tabs/profile'
    debugLogDiagnostics: true, // Hiển thị log navigation để debug
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: Stack(
              children: [
                TabPageView(
                  currentIndex: navigationShell.currentIndex,
                  onPageChanged: (index) {
                    final target = index < 0 ? 0 : (index > 3 ? 3 : index);
                    navigationShell.goBranch(target, initialLocation: true);
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomBottomNav(
                    selectedIndex: navigationShell.currentIndex,
                    onTap: (index) {
                      final target = index < 0 ? 0 : (index > 3 ? 3 : index);
                      navigationShell.goBranch(target, initialLocation: true);
                    },
                  ),
                ),
                const AiChatButton(),
              ],
            ),
          );
        },
        branches: [
          // Tab 1: Main
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tabs/main',
              pageBuilder: (c, s) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ]),
          // Tab 2: Desks
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tabs/desks',
              pageBuilder: (c, s) =>
                  const NoTransitionPage(child: DesksScreen()),
            ),
          ]),
          // Tab 3: Search
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tabs/search',
              pageBuilder: (c, s) =>
                  const NoTransitionPage(child: SearchScreen()),
            ),
          ]),
          // Tab 3: Profile/Login
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tabs/profile',
              pageBuilder: (c, s) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/word',
        builder: (context, state) {
          final entry = state.extra as WordEntry;
          return WordDetailScreen(entry: entry);
        },
      ),
    ],
    redirect: (context, state) {
      // Tuần 1: không bắt buộc login, không cần redirect guard.
      return null;
    },
  );
}
