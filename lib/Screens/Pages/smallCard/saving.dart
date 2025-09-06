import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        title: const Text(
          'Your Savings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
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
                  colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
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
                    '\$${savings.toStringAsFixed(2)}',
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
                _infoCard('Income', totalIncome, Colors.green),
                _infoCard('Expenses', totalExpenses, Colors.red),
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
          color: Colors.white,
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
              '\$${amount.toStringAsFixed(2)}',
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
              color: Colors.grey,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              isGuest ? "Welcome, Guest!" : "No Savings Data Yet!",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isGuest
                  ? "Start adding your income & expenses in guest mode to track savings."
                  : "Add income and expenses to see your savings grow.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                isGuest ? "Add Income/Expense" : "Add Data",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
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
