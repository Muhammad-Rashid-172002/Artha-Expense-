import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/addexpanse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Map<String, IconData> categoryIcons = {
  'Food': Icons.restaurant,
  'Transport': Icons.directions_car,
  'Shopping': Icons.shopping_bag,
  'Home': Icons.home,
  'Bills': Icons.receipt,
  'Health': Icons.local_hospital,
  'Entertainment': Icons.movie,
  'Other': Icons.category,
};

class CategoryDetailsScreen extends StatefulWidget {
  final String category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  double totalAllExpenses = 0;
  double totalIncome = 0;

  Future<void> _fetchIncome() async {
    if (userId == null) return;

    try {
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_income')
          .get();

      totalIncome = incomeSnapshot.docs.fold(0, (sum, doc) {
        final rawAmount = doc.data()['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount.toString()) ?? 0.0;
        return sum + amount;
      });
    } catch (e) {
      debugPrint("⚠️ Error fetching income: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExpenses() async {
    if (userId == null) return [];

    try {
      await _fetchIncome();

      final allSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .get();

      totalAllExpenses = allSnapshot.docs.fold(0, (sum, doc) {
        final rawAmount = doc.data()['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount.toString()) ?? 0.0;
        return sum + amount;
      });

      final categorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .where('category', isEqualTo: widget.category)
          .get();

      List<Map<String, dynamic>> expenses = categorySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'amount': (data['amount'] is num)
              ? (data['amount'] as num).toDouble()
              : double.tryParse(data['amount'].toString()) ?? 0.0,
          'createdAt': data['createdAt'],
          'category': data['category'] ?? 'Other',
        };
      }).toList();

      expenses.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate();
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return expenses;
    } catch (e) {
      debugPrint("🔥 Error fetching expenses: $e");
      return [];
    }
  }

  void _editExpense(Map<String, dynamic> expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddExpenseScreen(existingData: expense, docId: expense['id']),
      ),
    );
    setState(() {});
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.amber.shade600;
      case 'transport':
        return Colors.deepOrange.shade400;
      case 'shopping':
        return Colors.orangeAccent.shade200;
      case 'home':
        return Colors.amber.shade400;
      case 'bills':
        return Colors.deepOrange.shade600;
      case 'health':
        return Colors.orange.shade300;
      case 'entertainment':
        return Colors.amber.shade700;
      default:
        return Colors.orange.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 248, 222, 137)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Color(0xFFFFFFFF),
                title: Text(
                  "${widget.category} Expenses",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchExpenses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    final expenses = snapshot.data ?? [];
                    double spendingRatio = (totalIncome > 0)
                        ? totalAllExpenses / totalIncome
                        : 0.0;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 6,
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
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Income vs Expenses",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Income:",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        totalIncome.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Expenses:",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        totalAllExpenses.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrangeAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Spending Overview",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: spendingRatio.clamp(0.0, 1.0),
                                      minHeight: 10,
                                      color: Colors.amber.shade700,
                                      backgroundColor: Colors.orange.shade100,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${(spendingRatio * 100).toStringAsFixed(1)}% of income spent",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Expenses list
                        if (expenses.isEmpty)
                          const Center(
                            child: Text(
                              "No expenses in this category.",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenses[index];
                                final amount = expense['amount'] ?? 0.0;
                                final title = expense['title'] ?? '';
                                final category = expense['category'] ?? 'Other';

                                String formattedDate = 'Unknown Date';
                                final createdAt = expense['createdAt'];
                                if (createdAt != null &&
                                    createdAt is Timestamp) {
                                  try {
                                    final date = createdAt.toDate();
                                    formattedDate = DateFormat(
                                      'dd MMM yyyy – hh:mm a',
                                    ).format(date);
                                  } catch (e) {
                                    debugPrint("⚠️ Date parsing error: $e");
                                  }
                                }

                                final percentage = totalAllExpenses > 0
                                    ? ((amount / totalAllExpenses) * 100)
                                    : 0.0;

                                return Center(
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade300,
                                            Colors.deepOrange.shade200,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              leading: Icon(
                                                categoryIcons[category] ??
                                                    Icons.category,
                                                color: getCategoryColor(
                                                  category,
                                                ),
                                              ),
                                              title: Text(
                                                title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              subtitle: Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              trailing: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    amount.toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.amberAccent,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${percentage.toStringAsFixed(1)}%',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _editExpense(expense),
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                label: const Text("Edit"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.amber.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
