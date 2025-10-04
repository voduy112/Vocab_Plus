// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_controller.dart';
import 'router/app_router.dart';
import 'data/dictionary/dictionary_repository.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DictionaryRepository>(create: (_) => DictionaryRepository()),
        ChangeNotifierProvider(create: (_) => AuthController()..listenAuth()),
      ],
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
                seedColor: Colors.blue.shade400,
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
