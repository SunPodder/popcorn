import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'home_screen.dart';
import 'nickname_setup_screen.dart';
import 'scan_screen.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate background initialization work
    await Future.delayed(const Duration(seconds: 3));

    // Check if user has set nickname and completed scan
    final userService = UserService();
    final hasNickname = userService.hasNickname;
    final hasScanned = userService.hasScanned;

    // Navigate to appropriate screen
    if (mounted) {
      Widget nextScreen;
      if (!hasNickname) {
        nextScreen = const NicknameSetupScreen();
      } else if (!hasScanned) {
        nextScreen = const ScanScreen();
      } else {
        nextScreen = const HomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SvgPicture.asset('assets/images/logo.svg', width: 200, height: 200),
            const SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
