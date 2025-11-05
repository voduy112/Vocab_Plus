// core/widgets/animated_splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import '../../data/dictionary/dictionary_repository.dart';
import '../../features/decks/services/deck_preload_cache.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Wait for the first frame to ensure context is ready
    await WidgetsBinding.instance.endOfFrame;

    // Hide native splash screen
    FlutterNativeSplash.remove();

    // Start fade animation
    _fadeController.forward();

    // Minimum display time for splash screen (2 seconds)
    final minimumDisplayTime =
        Future.delayed(const Duration(milliseconds: 2000));

    // Load dictionary data and decks data in parallel
    try {
      final deckPreloadCache = DeckPreloadCache();
      // Create instance directly instead of using Provider
      // since this widget is outside the Provider tree
      final dictionaryRepository = DictionaryRepository();

      // Load dictionary and decks in parallel, ensuring minimum display time
      await Future.wait([
        // Load dictionary - this will parse in isolate so it won't block UI
        dictionaryRepository.loadAll(),
        // Preload decks data
        deckPreloadCache.preloadDecks(),
        // Ensure minimum display time
        minimumDisplayTime,
      ]);
    } catch (e) {
      // If loading fails, still wait for minimum display time
      await minimumDisplayTime;
    }

    // Navigate to main app using GoRouter
    if (mounted) {
      context.go('/tabs/main');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation from assets
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Lottie.asset(
                      'lib/core/assets/splash/Searching for word.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // App name with fade animation
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'Vocab Plus',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn vocabulary effectively',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
