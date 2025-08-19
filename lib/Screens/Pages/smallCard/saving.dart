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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final savings = totalIncome - totalExpenses;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          'Your Savings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            color: Colors.grey[850],
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white, width: 2),
            ),

            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.savings, size: 48, color: Colors.amber),
                  SizedBox(height: 10),
                  Text(
                    'Total Savings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(height: 10),
                  Text(
                    '${savings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Progress bar
                  LinearProgressIndicator(
                    value: totalIncome > 0
                        ? (savings / totalIncome).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Savings: ${(totalIncome > 0 ? (savings / totalIncome * 100).clamp(0.0, 100.0) : 0).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20),
                  Divider(),
                  Text(
                    'Income: ${totalIncome.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    'Expenses: ${totalExpenses.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
