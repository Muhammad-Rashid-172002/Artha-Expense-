import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class OnboardingScreen extends StatefulWidget {
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
      "image": "assets/images/Adobe Express - file (1).png",
    },
    {
      "title": "Simple Money Management",
      "description":
          "Get your notifications or alert when you do the over expenses",
      "image": "assets/images/Adobe Express - file (3).png",
    },
    {
      "title": "Easy to Track and Analyze",
      "description": "Tracking your expense help make sure you don't overspend",
      "image": "assets/images/Adobe Express - file (2).png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Image.asset(
                                onboardingData[index]['image']!,
                                height: 250,
                              )
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                curve: Curves.easeOut,
                              )
                              .moveY(begin: 40, end: 0, duration: 600.ms),
                          const SizedBox(height: 40),
                          Text(
                                onboardingData[index]['title']!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(
                                    0xFF37474F,
                                  ), // BlueGrey premium
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 900.ms)
                              .moveY(begin: 20, end: 0),

                          const SizedBox(height: 12),
                          Text(
                                onboardingData[index]['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey[700],
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

              /// Dots Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: onboardingData.length,
                effect: WormEffect(
                  activeDotColor: const Color(0xFFFFB300),
                  dotColor: Colors.blueGrey.shade200,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),

              const SizedBox(height: 30),

              /// LET'S GO Button or Loading Spinner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoading
                    ? const SpinKitCircle(color: Color(0xFFFFB300), size: 40)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor: Colors.blueAccent,
                        ),
                        onPressed: () async {
                          if (_currentIndex < onboardingData.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            setState(() => isLoading = true);

                            // Simulate delay or loading logic
                            await Future.delayed(const Duration(seconds: 2));

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginRequiredPage(),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "LET'S GO",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
