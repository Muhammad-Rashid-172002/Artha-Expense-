import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==== COLORS ====
const Color kAppBarColor = Color(0xFF1565C0); // Deep Blue
const Color kAppBarTextColor = Colors.white; // White text

const Color kBalanceCardColor = Color(0xFFFFD700); // Gold
const Color kBalanceCardTextColor = Colors.black; // Black text on gold

const Color kCardColor = Colors.white; // White background
const Color kCardTextColor = Colors.black87; // Dark text

const Color kHeadingTextColor = Color(0xFF0D47A1); // Dark Blue heading
const Color kSubtitleTextColor = Colors.black87; // Subtitles
const Color kBodyTextColor = Colors.black54; // Regular body text
const Color kFadedTextColor = Colors.grey; // Faded/secondary

const Color kButtonPrimary = Color(0xFF1565C0); // Deep Blue background
const Color kButtonPrimaryText = Colors.white; // White text

const Color kButtonSecondaryBorder = Color(0xFFFFD700); // Gold border
const Color kButtonSecondaryText = Color(0xFF1565C0); // Blue text

const Color kButtonDisabled = Color(0xFFBDBDBD); // Gray background
const Color kButtonDisabledText = Color(0xFF757575); // Light gray text

/// Temporary guest storage (shared with expenses & income screens)
List<Map<String, dynamic>> guestIncome = [];
List<Map<String, dynamic>> guestExpenses = [];

class Savings extends StatefulWidget {
  @override
  _SavingsState createState() => _SavingsState();
}

class _SavingsState extends State<Savings> with SingleTickerProviderStateMixin {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  bool isLoading = true;
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    fetchData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack));
  }

  Future<void> fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    double income = 0.0;
    double expenses = 0.0;

    if (userId == null) {
      /// Guest Mode
      for (var item in guestIncome) {
        income += (item['amount'] ?? 0).toDouble();
      }
      for (var item in guestExpenses) {
        expenses += (item['amount'] ?? 0).toDouble();
      }
    } else {
      /// Logged-in Mode (Firestore)
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_income')
          .get();

      for (var doc in incomeSnapshot.docs) {
        final data = doc.data();
        income += (data['amount'] ?? 0).toDouble();
      }

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .get();

      for (var doc in expenseSnapshot.docs) {
        final data = doc.data();
        expenses += (data['amount'] ?? 0).toDouble();
      }
    }

    setState(() {
      totalIncome = income;
      totalExpenses = expenses;
      isLoading = false;
    });
    _controller?.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final savings = totalIncome - totalExpenses;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Your Savings',
          style: TextStyle(
            color: kAppBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kAppBarColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kAppBarColor))
          : (totalIncome == 0 && totalExpenses == 0)
          ? _buildEmptyState(userId == null)
          : _buildSavingsDashboard(savings),
    );
  }

  Widget _buildSavingsDashboard(double savings) {
    double savingsPercent = totalIncome > 0
        ? (savings / totalIncome).clamp(0.0, 1.0)
        : 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _animation!,
            builder: (context, child) {
              return Transform.scale(scale: _animation!.value, child: child);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [kAppBarColor, kButtonPrimary], // Blue gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kAppBarColor.withOpacity(0.4),
                    offset: const Offset(0, 8),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.savings, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Total Savings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${savings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: savingsPercent,
                    backgroundColor: Colors.white38,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Savings: ${(savingsPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCard('Income', totalIncome, kAppBarColor),
                _infoCard('Expenses', totalExpenses, kButtonSecondaryBorder),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isGuest) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: kFadedTextColor,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              isGuest ? "Welcome, Guest!" : "No Savings Data Yet!",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kBodyTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isGuest
                  ? "Start adding your income & expenses in guest mode to track savings."
                  : "Add income and expenses to see your savings grow.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kSubtitleTextColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add, color: kButtonPrimaryText),
              label: Text(
                isGuest ? "Add Income/Expense" : "Add Data",
                style: const TextStyle(fontSize: 16, color: kButtonPrimaryText),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
