import 'package:flutter/material.dart';
import 'theme/popcorn_theme.dart';
import 'screens/splash_screen.dart';

void main() {
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
