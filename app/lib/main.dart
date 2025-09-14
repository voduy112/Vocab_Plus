// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/widgets/animated_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash screen until Flutter is ready
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AnimatedSplashScreen(),
      routes: {
        '/tabs/main': (context) => const App(),
      },
    );
  }
}
