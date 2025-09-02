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
      // First time user - show onboarding screen
      await prefs.setBool('isFirstTime', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
    } else if (user != null) {
      // User is signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Not signed in - go to sign-in screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/splashScreen.png', width: 200),
              const SizedBox(height: 20),
              // App Name
              Text(
                    "Welcome to Artha..",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF37474F), // BlueGrey (luxury dark)
                      letterSpacing: 1.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 1000.ms)
                  .moveY(begin: 20, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 12),

              // Tagline
              Text(
                    "Track Today, Plan Tomorrow.",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: const Color(0xFFF57C00), // Deep Orange accent
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.7,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 800.ms)
                  .slideY(begin: 0.5, end: 0),
              const SizedBox(height: 40),
              const SpinKitCircle(color: Colors.white, size: 50.0),
            ],
          ),
        ),
      ),
    );
  }
}
