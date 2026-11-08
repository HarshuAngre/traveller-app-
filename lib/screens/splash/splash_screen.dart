import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    _splashTimer = Timer(const Duration(seconds: 3), _checkAuthentication);
  }

  void _checkAuthentication() {
    if (!mounted) return;

    // Retrieve the session restored by Supabase during app startup.
    final session = Supabase.instance.client.auth.currentSession;

    // A saved session means the user is already authenticated.
    final Widget destination = session != null
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Icon(
                  Icons.flight_takeoff,
                  color: Colors.white,
                  size: 70,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "VoyageMate",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Explore Smarter.\nTravel Better.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              const CircularProgressIndicator(color: Colors.white),

              const SizedBox(height: 20),

              const Text("Loading...", style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
