import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==== COLOR CONSTANTS ====
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

// Custom category colors for Pie Chart
const Map<String, Color> kCategoryColors = {
  'food': Color(0xFFFFB74D), // Orange
  'transport': Color(0xFF4FC3F7), // Light Blue
  'shopping': Color(0xFF81C784), // Light Green
  'entertainment': Color(0xFFE57373), // Red
  'bills': Color(0xFFFFD54F), // Yellow
  'health': Color(0xFFBA68C8), // Purple
  'other': Color(0xFF90A4AE), // Grey Blue
};

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
    return kCategoryColors[category.toLowerCase()] ?? kCategoryColors['other']!;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = categoryTotals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monthly Budget Overview",
          style: TextStyle(
            color: kAppBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kAppBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kAppBarTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kAppBarTextColor),
            onPressed: fetchCategoryData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kAppBarColor))
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
            color: kHeadingTextColor,
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
                        ? [kButtonPrimary, Colors.teal.shade300]
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
                      color: kButtonPrimaryText,
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
              color: kBalanceCardColor,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isGuest ? "Welcome, Guest!" : "No Budget Data Yet!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kCardTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isGuest
                  ? "Start adding your expenses to see your spending breakdown."
                  : "Set up your budget and start tracking your expenses today.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kBodyTextColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add, color: kButtonPrimaryText),
              label: Text(
                isGuest ? "Add Your First Expense" : "Set Up Budget",
                style: const TextStyle(fontSize: 16, color: kButtonPrimaryText),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonPrimary,
                foregroundColor: kButtonPrimaryText,
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
