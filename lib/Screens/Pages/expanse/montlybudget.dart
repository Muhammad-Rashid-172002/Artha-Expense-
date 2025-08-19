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

  @override
  void initState() {
    super.initState();
    fetchCategoryData();
  }

  Future<void> fetchCategoryData() async {
    if (userId == null) return;

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
        return Colors.blueAccent;
      case 'transport':
        return Colors.deepPurple;
      case 'shopping':
        return Colors.orangeAccent;
      case 'entertainment':
        return Colors.green;
      case 'bills':
        return Colors.redAccent;
      case 'health':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = categoryTotals.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
          "Monthly Budget Overview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: hasData
          ? Column(
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
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryTotals.length,
                    itemBuilder: (context, index) {
                      final entry = categoryTotals.entries.elementAt(index);
                      final total = categoryTotals.values.fold(
                        0.0,
                        (a, b) => a + b,
                      );
                      final percentage = (entry.value / total) * 100;

                      return Center(
                        child: Card(
                          color: Colors.grey[850],
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Colors.white24,
                              width: 1.5,
                            ),
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
                                        builder: (context) =>
                                            CategoryDetailsScreen(
                                              category: entry.key,
                                            ),
                                      ),
                                    );
                                    // You can add your logic here
                                    print("Button pressed for ${entry.key}");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey[700],
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
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
