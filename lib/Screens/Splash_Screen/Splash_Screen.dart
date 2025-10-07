import 'package:expanse_tracker_app/Screens/HomeScreen/homescreen.dart';
import 'package:expanse_tracker_app/Screens/OnboardingScreens/onboardingscreens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 4));

    final user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or animated icon
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),

              const SizedBox(height: 25),

              // App Name
              Text(
                "BillSnap AI",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 800.ms)
                  .moveY(begin: 30, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 10),

              // Tagline
              Text(
                "Smart Finance. Smarter You.",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .slideY(begin: 0.4, end: 0),

              const SizedBox(height: 40),

              // Loading animation
              const SpinKitThreeBounce(
                color: Colors.white,
                size: 28,
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
