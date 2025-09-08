import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
      "title": "Note Down Expenses",
      "description": "Daily note your expenses to help manage money",
      "image": "assets/animation_assets/Business Growth.json",
    },
    {
      "title": "Simple Money Management",
      "description":
          "Get your notifications or alert when you do the over expenses",
      "image": "assets/animation_assets/growth.json",
    },
    {
      "title": "Easy to Track and Analyze",
      "description":
          "Tracking your expense helps make sure you don't overspend",
      "image": "assets/animation_assets/increment.json",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (_, index) {
                  final item = onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Lottie animation
                        Lottie.asset(item['image']!, height: 250),
                        const SizedBox(height: 40),
                        Text(
                              item['title']!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kHeadingTextColor, // Updated
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 900.ms)
                            .moveY(begin: 20, end: 0),
                        const SizedBox(height: 12),
                        Text(
                              item['description']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: kSubtitleTextColor, // Updated
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
              effect: WormEffect(
                activeDotColor: kButtonPrimary, // Updated
                dotColor: kFadedTextColor, // Updated
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            const SizedBox(height: 30),

            // LET'S GO button or spinner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? SpinKitCircle(color: kButtonPrimary, size: 40) // Updated
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonPrimary, // Updated
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: kAppBarColor, // Updated
                      ),
                      onPressed: () async {
                        if (_currentIndex < onboardingData.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
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
                      child: const Text(
                        "LET'S GO",
                        style: TextStyle(
                          fontSize: 16,
                          color: kButtonPrimaryText, // Updated
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
