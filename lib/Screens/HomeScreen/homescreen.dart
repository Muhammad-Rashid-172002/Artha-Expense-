import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop()
import 'package:expanse_tracker_app/Screens/Pages/HomePage.dart';
import 'package:expanse_tracker_app/Screens/Pages/Notification.dart';
import 'package:expanse_tracker_app/Screens/Pages/SettingsPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/TaskPage.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    HomePage(),
    TaskPage(),
    NotificationsPage(),
    SettingsPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddScreenSafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Add Something")),
            body: const Center(child: Text("Add Screen Placeholder")),
          ),
        ),
      );
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Press again to exit')));
      return Future.value(false);
    }
    return Future.value(true); // Exit app
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exit = await _onWillPop();
        if (exit) {
          SystemNavigator.pop(); // Closes the app
        }
        return false;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),

        // Bottom Bar
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFC107), // Amber
                Color(0xFFFF5722), // Deep Orange
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            elevation: 0,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Left side
                  Row(
                    children: [
                      _buildNavItem(Icons.home_outlined, 0),
                      const SizedBox(width: 12),
                      _buildNavItem(Icons.check_box_outlined, 1),
                    ],
                  ),
                  // Right side
                  Row(
                    children: [
                      _buildNavItem(Icons.notifications_outlined, 2),
                      const SizedBox(width: 12),
                      _buildNavItem(Icons.settings_outlined, 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Custom Nav Item with active/inactive states
  Widget _buildNavItem(IconData icon, int index) {
    final bool isActive = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFC107),
                  Color(0xFFFF5722),
                ], // amber → deep orange
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: isActive ? 30 : 26,
          color: isActive ? Colors.white : Colors.white70,
        ),
        onPressed: () => _onTabTapped(index),
      ),
    );
  }
}
