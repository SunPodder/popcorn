import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/popcorn_theme.dart';
import 'screens/splash_screen.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize user service
  await UserService().initialize();

  runApp(const PopcornApp());
}

class PopcornApp extends StatelessWidget {
  const PopcornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Popcorn',
      debugShowCheckedModeBanner: false,
      theme: PopcornTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
