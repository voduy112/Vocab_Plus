// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_controller.dart';
import 'core/widgets/animated_splash_screen.dart';
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController()..listenAuth(),
      child: Builder(
        builder: (context) {
          final router = createRouter(context.read<AuthController>());
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
                background: Colors.white,
                surface: Colors.white,
              ),
            ),
            themeMode: ThemeMode.light,
          );
        },
      ),
    );
  }
}
