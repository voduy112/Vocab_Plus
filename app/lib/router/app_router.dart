// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/desks/views/desk_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../core/auth/auth_controller.dart';

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/tabs/main',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.folder_outlined), label: 'Desks'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline), label: 'Profile'),
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
                  const NoTransitionPage(child: DeskScreen()),
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
    ],
    redirect: (context, state) {
      // Tuần 1: không bắt buộc login, không cần redirect guard.
      return null;
    },
  );
}
