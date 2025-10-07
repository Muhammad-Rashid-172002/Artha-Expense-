import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF0F2027);
const Color kPrimaryDark2 = Color(0xFF203A43);
const Color kPrimaryDark3 = Color(0xFF2C5364);

const Color kCardColor = Colors.white;
const Color kFadedTextColor = Colors.grey;

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
      duration: const Duration(milliseconds: 800),
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
      // Guest Mode
      income = 0.0;
      expenses = 0.0;
    } else {
      // Firestore Mode
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_income')
          .get();
      for (var doc in incomeSnapshot.docs) {
        income += (doc.data()['amount'] ?? 0).toDouble();
      }

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .get();
      for (var doc in expenseSnapshot.docs) {
        expenses += (doc.data()['amount'] ?? 0).toDouble();
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
    final savings = totalIncome - totalExpenses;
    final savingsPercent = totalIncome > 0
        ? (savings / totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Your Savings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _animation!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation!.value,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [kPrimaryDark2, kPrimaryDark3],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.savings,
                            size: 60,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total Savings',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${savings.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: savingsPercent,
                              minHeight: 12,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amberAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Savings: ${(savingsPercent * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
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
                        _infoCard(
                          'Income',
                          totalIncome,
                          Colors.greenAccent.shade400,
                        ),
                        _infoCard(
                          'Expenses',
                          totalExpenses,
                          Colors.redAccent.shade400,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPrimaryDark2.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
