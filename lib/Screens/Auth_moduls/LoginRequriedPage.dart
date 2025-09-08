import 'package:expanse_tracker_app/Screens/Auth_moduls/signupscreen.dart';
import 'package:expanse_tracker_app/Screens/HomeScreen/homescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:flutter/material.dart';

class LoginRequiredPage extends StatelessWidget {
  const LoginRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Colors.grey.shade100, // optional background color
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon with circular background
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kButtonPrimary, // updated
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.white, // stays white
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                const Text(
                  "Please Login",
                  style: TextStyle(
                    color: kHeadingTextColor, // updated
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                const Text(
                  "Login to save your data securely in the cloud",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: kBodyTextColor, // updated
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button with Gradient
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          kButtonPrimary,
                          kAppBarColor,
                        ], // updated gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      icon: const Icon(
                        Icons.login,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        "Login Now",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => SignupScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Skip Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(
                        color: kButtonPrimary,
                        width: 2,
                      ), // updated
                      foregroundColor: kButtonPrimary, // updated
                    ),
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: kButtonPrimary, // updated
                    ),
                    label: const Text(
                      "Continue as Guest",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kBodyTextColor, // updated
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
