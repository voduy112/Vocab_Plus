// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'firebase_options.dart';
import 'app.dart';
import 'features/notifications/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash screen until Flutter is ready
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo timezone database
  tz.initializeTimeZones();

  // Khởi tạo notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDueVocabularyNotifications();

  runApp(const App());
}
