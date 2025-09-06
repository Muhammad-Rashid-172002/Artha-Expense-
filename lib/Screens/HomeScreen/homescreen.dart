import 'package:expanse_tracker_app/Screens/Pages/Update_income/AddIncomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/addexpanse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press again to exit'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  void _openAddScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Add Transaction",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Expense Button
                  _bottomSheetButton(
                    icon: Icons.arrow_upward,
                    label: "Expense",
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(),
                        ),
                      );
                      // Your ExpensePage route
                    },
                  ),
                  // Income Button
                  _bottomSheetButton(
                    icon: Icons.arrow_downward,
                    label: "Income",
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddIncomeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSheetButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exit = await _onWillPop();
        if (exit) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.grey.shade100,
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200.withOpacity(0.6),
                spreadRadius: 4,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _openAddScreen,
            backgroundColor: Colors.transparent,
            elevation: 0,
            splashColor: Colors.greenAccent,
            child: Icon(Icons.add, size: 36, color: Colors.white),
          ),
        ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            color: Colors.transparent,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      _buildNavItem(Icons.home_outlined, 0),
                      const SizedBox(width: 16),
                      _buildNavItem(Icons.check_box_outlined, 1),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNavItem(Icons.notifications_outlined, 2),
                      const SizedBox(width: 16),
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

  Widget _buildNavItem(IconData icon, int index) {
    final bool isActive = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
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
