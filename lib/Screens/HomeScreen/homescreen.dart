import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/AIChatBotPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/AiInsightsPage.dart' hide kPrimaryGradient;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expanse_tracker_app/Screens/Pages/HomePage.dart' hide kPrimaryGradient;
import 'package:expanse_tracker_app/Screens/Pages/Notification.dart';
import 'package:expanse_tracker_app/Screens/Pages/SettingsPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/TaskPage.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = const [
    HomePage(),
    TaskPage(),
    AiInsightsPage(),
    Aichatbotpage(),
    NotificationsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press again to exit',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: kPrimaryGradient.colors.last,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exit = await _onWillPop();
        if (exit) SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        extendBody: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kPrimaryGradient.colors.first.withOpacity(0.08),
                kPrimaryGradient.colors.last.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryGradient.colors.first.withOpacity(0.9),
                  kPrimaryGradient.colors.last.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                showUnselectedLabels: true,
                selectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                items: [
                  _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                  _buildNavItem(Icons.check_box_outlined, Icons.check_box, 'Tasks', 1),
                  _buildNavItem(Icons.lightbulb_outline, Icons.lightbulb, 'AI Insights', 2),
                  _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'AI Chat', 3),
                  _buildNavItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', 4),
                  _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: _currentIndex == index
            ? BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGradient.colors.last.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Icon(icon, color: _currentIndex == index ? Colors.white : Colors.white70),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGradient.colors.last.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(activeIcon, color: Colors.white),
      ),
      label: label,
    );
  }
}
