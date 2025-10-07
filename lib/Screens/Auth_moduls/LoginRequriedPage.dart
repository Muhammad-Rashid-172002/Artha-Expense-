import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/signupscreen.dart';
import 'package:expanse_tracker_app/Screens/HomeScreen/homescreen.dart';

/// 🎨 Color constants
const kButtonPrimary = Color(0xFF6C63FF);
const kAppBarColor = Color(0xFF5A55DA);
const kHeadingTextColor = Color(0xFF1A1A1A);
const kBodyTextColor = Color(0xFF6C757D);

class LoginRequiredPage extends StatefulWidget {
  const LoginRequiredPage({super.key});

  @override
  State<LoginRequiredPage> createState() => _LoginRequiredPageState();
}

class _LoginRequiredPageState extends State<LoginRequiredPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔒 Circular Lock Icon
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          color: kButtonPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 🧩 Title
                      Text(
                        "Welcome to BillSnap",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 💬 Subtitle
                      Text(
                        "Login to sync your data securely across devices and manage your finances effortlessly.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // 🔑 Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: kButtonPrimary,
                            elevation: 3,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign In & Sync Data",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 🚪 Continue as Guest
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: const BorderSide(color: Colors.white, width: 2),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Explore Without Login",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.08),

                      // 🔻 Footer Text
                      Text(
                        "Your financial data stays private & secure 🔒",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
