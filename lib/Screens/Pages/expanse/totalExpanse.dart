// main imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'addexpanse.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final today = DateTime.now();
  final daysOfWeek = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
  final double budget = 1600;

  List<Map<String, dynamic>> expenses = [];
  double totalSpent = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    userId = user.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_expenses')
        .orderBy('date', descending: true)
        .get();

    double sum = 0;
    List<Map<String, dynamic>> list = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amt = double.tryParse(data['amount'].toString()) ?? 0;
      sum += amt;
      list.add({...data, 'id': doc.id});
    }

    setState(() {
      expenses = list;
      totalSpent = sum;
    });
  }

  Map<String, double> getCategoryData() {
    final Map<String, double> map = {};
    for (var e in expenses) {
      final cat = e['category'] as String? ?? 'Other';
      final amt = double.tryParse(e['amount'].toString()) ?? 0;
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map;
  }

  Future<void> _onAddExpense() async {
    final newExp = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (newExp != null && newExp['amount'] != null && newExp['id'] != null) {
      final exists = expenses.any((e) => e['id'] == newExp['id']);
      if (!exists) {
        final amt = double.tryParse(newExp['amount'].toString()) ?? 0;
        setState(() {
          expenses.insert(0, newExp);
          totalSpent += amt;
        });
      }
    }
  }

  Future<void> _editExpense(int idx) async {
    final exp = expenses[idx];
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          existingData: exp,
          docId: exp['id'], // Ensure you're passing the document ID
        ),
      ),
    );

    if (updated != null &&
        updated['amount'] != null &&
        updated['id'] == exp['id']) {
      setState(() {
        expenses[idx] = updated;

        // Update totalSpent accurately
        final oldAmt = double.tryParse(exp['amount'].toString()) ?? 0;
        final newAmt = double.tryParse(updated['amount'].toString()) ?? 0;
        totalSpent = totalSpent - oldAmt + newAmt;
      });
    }
  }

  Future<void> _deleteExpense(int idx) async {
    if (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirm"),
            content: const Text("Delete this expense?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) !=
        true)
      return;

    final exp = expenses[idx];
    final amt = double.tryParse(exp['amount'].toString()) ?? 0;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_expenses')
        .doc(exp['id'])
        .delete();
    setState(() {
      expenses.removeAt(idx);
      totalSpent -= amt;
    });
  }

  final Map<String, IconData> categoryIcons = {
    'Rent': Icons.home,
    'Shopping': Icons.shopping_bag,
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Health': Icons.health_and_safety,
    'Entertainment': Icons.movie,
    'Bills': Icons.receipt,
    'Education': Icons.school,
    'Other': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    final startWeek = today.subtract(Duration(days: today.weekday - 1));
    final percent = budget == 0
        ? 0
        : ((totalSpent / budget) * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Total Expenses",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month & Year
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Weekday Calendar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final today = DateTime.now();
                        final startOfWeek = today.subtract(
                          Duration(days: today.weekday - 1),
                        );
                        final currentDay = startOfWeek.add(
                          Duration(days: index),
                        );
                        final daysOfWeek = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        final isToday =
                            today.day == currentDay.day &&
                            today.month == currentDay.month &&
                            today.year == currentDay.year;

                        return Column(
                          children: [
                            Text(
                              daysOfWeek[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isToday
                                  ? Colors.white
                                  : Colors.transparent,
                              child: Text(
                                '${currentDay.day}',
                                style: TextStyle(
                                  color: isToday ? Colors.blue : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                "${totalSpent.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You have spent total",
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              "${percent.toStringAsFixed(0)}% of your budget",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Spends"),
                  Tab(text: "Categories"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Spends Tab
                  ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final e = expenses[i];
                      final amt = double.tryParse(e['amount'].toString()) ?? 0;
                      return Slidable(
                        key: ValueKey(e['id']),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.4,
                          children: [
                            SlidableAction(
                              icon: Icons.edit,
                              label: "Edit",
                              onPressed: (_) => _editExpense(i),
                            ),
                            SlidableAction(
                              icon: Icons.delete,
                              label: "Delete",
                              backgroundColor: Colors.red,
                              onPressed: (_) => _deleteExpense(i),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              categoryIcons[e['category']] ?? Icons.category,
                              color: Colors.blue,
                            ),
                            title: Text(e['title'] ?? ''),
                            subtitle: Text(e['date'] ?? ''),
                            trailing: Text(
                              "${amt.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Categories tab with Slidable per expense
                  ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final e = expenses[i];
                      final amt = double.tryParse(e['amount'].toString()) ?? 0;
                      return Slidable(
                        key: ValueKey("cat-${e['id']}"),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.4,
                          children: [
                            SlidableAction(
                              icon: Icons.edit,
                              label: "Edit",
                              onPressed: (_) => _editExpense(i),
                            ),
                            SlidableAction(
                              icon: Icons.delete,
                              label: "Delete",
                              backgroundColor: Colors.red,
                              onPressed: (_) => _deleteExpense(i),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: ListTile(
                            leading: Icon(
                              categoryIcons[e['category']] ?? Icons.category,
                              color: Colors.blue,
                            ),

                            title: Text(e['category'] ?? 'Other'),
                            subtitle: Text(e['title'] ?? ''),
                            trailing: Text("${amt.toStringAsFixed(2)}"),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddExpense,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
