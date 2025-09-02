import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, double> categoryTotals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryData();
  }

  Future<void> fetchCategoryData() async {
    if (userId == null) {
      setState(() {
        categoryTotals = {};
        isLoading = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_expenses')
        .get();

    final Map<String, double> totals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Other';
      final amount = (data['amount'] ?? 0).toDouble();

      if (totals.containsKey(category)) {
        totals[category] = totals[category]! + amount;
      } else {
        totals[category] = amount;
      }
    }

    setState(() {
      categoryTotals = totals;
      isLoading = false;
    });
  }

  List<PieChartSectionData> getPieChartSections() {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: getColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.amber.shade600;
      case 'transport':
        return Colors.deepOrange.shade400;
      case 'shopping':
        return Colors.orangeAccent.shade200;
      case 'entertainment':
        return Colors.amber.shade400;
      case 'bills':
        return Colors.orange.shade700;
      case 'health':
        return Colors.deepOrange.shade200;
      default:
        return Colors.orange.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = categoryTotals.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color.fromARGB(255, 248, 222, 137),
          ], // Gradient background
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Keep gradient visible
        appBar: AppBar(
          title: const Text(
            "Monthly Budget Overview",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFFFFFFF),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : hasData
            ? _buildBudgetOverview()
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            height: 200,
            width: 200,
            child: PieChart(
              PieChartData(
                sections: getPieChartSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Category Breakdown",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categoryTotals.length,
            itemBuilder: (context, index) {
              final entry = categoryTotals.entries.elementAt(index);
              final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
              final percentage = (entry.value / total) * 100;

              return Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.deepOrange.shade200,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.label,
                              color: getColor(entry.key),
                            ),
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: getColor(entry.key),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetailsScreen(
                                    category: entry.key,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("View Details"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isGuest = userId == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.amber.shade700,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isGuest ? "Welcome, Guest!" : "No Budget Data Yet!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isGuest
                  ? "Start adding your expenses to track where your money goes."
                  : "Set up your budget and start tracking your expenses today.",
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
                isGuest ? "Add Your First Expense" : "Set Up Budget",
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
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
