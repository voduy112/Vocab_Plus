// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/decks/views/deck_screen.dart';
import '../features/decks/views/add_vocabulary_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/search/views/search_screen.dart';
import '../../features/search/views/word_detail_screen.dart';
import '../../data/dictionary/models.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/widgets/tab_page_view.dart';
import '../../core/widgets/custom_bottom_nav.dart';
import '../../core/widgets/ai_chat_button.dart';
import '../../core/models/deck.dart';
import '../../core/models/vocabulary.dart';
import '../../features/pronunciation/views/select_deck_screen.dart';
import '../../features/pronunciation/views/pronunciation_practice_screen.dart';
import '../../core/widgets/animated_splash_screen.dart';

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/splash', // Start with splash screen
    debugLogDiagnostics: true, // Hiển thị log navigation để debug
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AnimatedSplashScreen(),
        ),
      ),
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
          // Tab 2: Decks
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tabs/decks',
              pageBuilder: (c, s) =>
                  const NoTransitionPage(child: DecksScreen()),
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
      GoRoute(
        path: '/add-vocabulary',
        builder: (context, state) {
          final deck = state.extra as Deck;
          return AddVocabularyScreen(deck: deck);
        },
      ),
      GoRoute(
        path: '/edit-vocabulary',
        builder: (context, state) {
          final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
          final deck = args['deck'] as Deck;
          final vocabulary = args['vocabulary'] as Vocabulary;
          return AddVocabularyScreen(deck: deck, vocabulary: vocabulary);
        },
      ),
      GoRoute(
        path: '/pronunciation/select-deck',
        builder: (context, state) => const PronunciationSelectDeckScreen(),
      ),
      GoRoute(
        path: '/pronunciation/practice',
        builder: (context, state) {
          final deck = state.extra as Deck;
          return PronunciationPracticeScreen(deck: deck);
        },
      ),
    ],
    redirect: (context, state) {
      // Tuần 1: không bắt buộc login, không cần redirect guard.
      return null;
    },
  );
}
