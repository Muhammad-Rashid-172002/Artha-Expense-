import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Import Guest Expense Store

class BudgetScreen extends StatefulWidget {
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, double> categoryTotals = {};
  bool isLoading = true;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    fetchCategoryData();
  }

  Future<void> fetchCategoryData() async {
    if (userId == null) {
      // ✅ Guest Mode: calculate from GuestExpenseStore
      final Map<String, double> totals = {};
      for (var exp in GuestExpenseStore.expenses) {
        final category = exp['category'] ?? 'Other';
        final amount = (exp['amount'] ?? 0).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }

      setState(() {
        categoryTotals = totals;
        isLoading = false;
      });
      return;
    }

    // ✅ Logged-in Mode: fetch from Firestore
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
      totals[category] = (totals[category] ?? 0) + amount;
    }

    setState(() {
      categoryTotals = totals;
      isLoading = false;
    });
  }

  List<PieChartSectionData> getPieChartSections() {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return categoryTotals.entries.mapIndexed((index, entry) {
      final percentage = total == 0 ? 0 : (entry.value / total) * 100;
      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        color: getColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.green.shade400;
      case 'transport':
        return Colors.teal.shade400;
      case 'shopping':
        return Colors.lightGreen.shade300;
      case 'entertainment':
        return Colors.greenAccent.shade400;
      case 'bills':
        return Colors.lime.shade700;
      case 'health':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = categoryTotals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monthly Budget Overview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchCategoryData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : hasData
          ? _buildBudgetOverview()
          : _buildEmptyState(),
    );
  }

  Widget _buildBudgetOverview() {
    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() {
              touchedIndex = (touchedIndex == null) ? 0 : null;
            });
          },
          child: Center(
            child: SizedBox(
              height: 220,
              width: 220,
              child: PieChart(
                PieChartData(
                  sections: getPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        touchedIndex = pieTouchResponse
                            ?.touchedSection
                            ?.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Category Breakdown",
          style: TextStyle(
            fontSize: 20,
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
              final percentage = total == 0 ? 0 : (entry.value / total) * 100;
              final isSelected = touchedIndex == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                transform: isSelected
                    ? (Matrix4.identity()..scale(1.05))
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Colors.green.shade500, Colors.teal.shade300]
                        : [Colors.green.shade300, Colors.lightGreen.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.label,
                    color: getColor(entry.key),
                    size: isSelected ? 36 : 28,
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSelected ? 18 : 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: isSelected ? 16 : 14,
                      color: getColor(entry.key),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      touchedIndex = index;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryDetailsScreen(category: entry.key),
                      ),
                    );
                  },
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
              color: Colors.green.shade400,
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
                  ? "Start adding your expenses to see your spending breakdown."
                  : "Set up your budget and start tracking your expenses today.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                isGuest ? "Add Your First Expense" : "Set Up Budget",
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

// Helper extension for map with index
extension IndexedMap<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) sync* {
    int index = 0;
    for (var item in this) yield f(index++, item);
  }
}
