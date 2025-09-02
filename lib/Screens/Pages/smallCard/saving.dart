import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Savings extends StatefulWidget {
  @override
  _SavingsState createState() => _SavingsState();
}

class _SavingsState extends State<Savings> {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    double income = 0.0;
    double expenses = 0.0;

    // Fetch income
    final incomeSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_income')
        .get();

    for (var doc in incomeSnapshot.docs) {
      final data = doc.data();
      income += (data['amount'] ?? 0).toDouble();
    }

    // Fetch expenses
    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_expenses')
        .get();

    for (var doc in expenseSnapshot.docs) {
      final data = doc.data();
      expenses += (data['amount'] ?? 0).toDouble();
    }

    setState(() {
      totalIncome = income;
      totalExpenses = expenses;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final savings = totalIncome - totalExpenses;

    return Scaffold(
      // ✅ Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 254, 217, 96),
            ], // Gradient background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text(
                  'Your Savings',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.black),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (userId == null ||
                          (totalIncome == 0 && totalExpenses == 0))
                    ? _buildEmptyState(userId == null)
                    : _buildSavingsCard(savings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Savings UI when data exists
  Widget _buildSavingsCard(double savings) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Card(
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.deepOrange.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.savings, size: 48, color: Colors.deepOrange),
                  const SizedBox(height: 10),
                  const Text(
                    'Total Savings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${savings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress bar
                  LinearProgressIndicator(
                    value: totalIncome > 0
                        ? (savings / totalIncome).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepOrange,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Savings: ${(totalIncome > 0 ? (savings / totalIncome * 100).clamp(0.0, 100.0) : 0).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  Text(
                    'Income: ${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    'Expenses: ${totalExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state for Guest & No Data
  Widget _buildEmptyState(bool isGuest) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.amber,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isGuest ? "Welcome, Guest!" : "No Savings Data Yet!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isGuest
                  ? "Login and start adding your income & expenses to track savings."
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
                isGuest ? "Login to Start" : "Add Income/Expense",
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
