import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  bool isLoading = false;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Track Smarter",
      "description": "Note your daily income & expenses effortlessly.",
      "image": "assets/animation_assets/Business Growth.json",
    },
    {
      "title": "AI Money Insights",
      "description": "Get AI-powered spending tips and smart alerts.",
      "image": "assets/animation_assets/growth.json",
    },
    {
      "title": "Plan Your Future",
      "description": "Achieve goals faster with automated budgeting tools.",
      "image": "assets/animation_assets/increment.json",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (_, index) {
                    final item = onboardingData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          // Lottie animation
                          Animate(
                            effects: [
                              FadeEffect(duration: 800.ms),
                              MoveEffect(
                                begin: const Offset(0, 20),
                                end: Offset.zero,
                              ),
                            ],
                            child: Lottie.asset(item['image']!, height: 250),
                          ),

                          const SizedBox(height: 40),

                          // Title
                          Text(
                                item['title']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 900.ms)
                              .moveY(begin: 20, end: 0),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                                item['description']!,
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 800.ms)
                              .slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Smooth Page Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: onboardingData.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Color(0xFF00C6FF),
                  dotColor: Colors.white38,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                  expansionFactor: 3,
                ),
              ),
              const SizedBox(height: 30),

              // LET'S GO button or spinner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: isLoading
                    ? const SpinKitThreeBounce(color: Colors.white, size: 25)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C6FF),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: Colors.blueAccent.withOpacity(0.5),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          if (_currentIndex < onboardingData.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            setState(() => isLoading = true);
                            await Future.delayed(const Duration(seconds: 2));
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginRequiredPage(),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          _currentIndex == onboardingData.length - 1
                              ? "Get Started"
                              : "Next",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
