import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addexpanse.dart';

/// Temporary storage for guest expenses
class GuestExpenseStore {
  static final List<Map<String, dynamic>> _expenses = [];

  static List<Map<String, dynamic>> get expenses => _expenses;

  static void addExpense(String title, String category, double amount) {
    _expenses.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "title": title,
      "category": category,
      "amount": amount,
      "date": DateFormat.yMMMd().format(DateTime.now()),
    });
  }

  static void deleteExpense(String id) {
    _expenses.removeWhere((exp) => exp["id"] == id);
  }

  static void editExpense(
    String id,
    String title,
    String category,
    double amount,
  ) {
    final index = _expenses.indexWhere((exp) => exp["id"] == id);
    if (index != -1) {
      _expenses[index] = {
        "id": id,
        "title": title,
        "category": category,
        "amount": amount,
        "date": DateFormat.yMMMd().format(DateTime.now()),
      };
    }
  }
}

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final today = DateTime.now();
  final double budget = 1600;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _onAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    setState(() {}); // refresh UI after adding
  }

  Future<void> _editExpense(Map<String, dynamic> data, String id) async {
    if (userId == null) {
      // Guest mode: allow local edit
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(existingData: data, docId: id),
        ),
      );
      setState(() {});
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(existingData: data, docId: id),
      ),
    );
  }

  Future<void> _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Confirm", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Delete this expense?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (userId == null) {
      setState(() {
        GuestExpenseStore.deleteExpense(id);
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .doc(id)
          .delete();
    }
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

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
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
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// Calendar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (index) {
                          final currentDay = startWeek.add(
                            Duration(days: index),
                          );
                          final isToday =
                              currentDay.day == today.day &&
                              currentDay.month == today.month &&
                              currentDay.year == today.year;
                          return Column(
                            children: [
                              Text(
                                [
                                  "Mon",
                                  "Tue",
                                  "Wed",
                                  "Thu",
                                  "Fri",
                                  "Sat",
                                  "Sun",
                                ][index],
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
                                    color: isToday
                                        ? Colors.amber
                                        : Colors.white,
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
            ),

            /// Total spent
            _buildTotalSpent(),

            /// Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.amber,
                tabs: const [
                  Tab(text: "Spends"),
                  Tab(text: "Categories"),
                ],
              ),
            ),

            /// Expense lists
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpenseList(showCategory: false),
                  _buildExpenseList(showCategory: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddExpense,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        backgroundColor: Colors.amber,
      ),
    );
  }

  /// Total Spent Widget
  Widget _buildTotalSpent() {
    if (userId == null) {
      double totalSpent = GuestExpenseStore.expenses.fold(
        0.0,
        (sum, exp) => sum + (exp['amount'] ?? 0),
      );
      final percent = budget == 0
          ? 0
          : ((totalSpent / budget) * 100).clamp(0, 100);

      return _buildTotalCard(totalSpent, percent.toDouble());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalSpent +=
                double.tryParse((doc['amount'] ?? '0').toString()) ?? 0;
          }
        }
        final percent = budget == 0
            ? 0
            : ((totalSpent / budget) * 100).clamp(0, 100);

        return _buildTotalCard(totalSpent, percent.toDouble());
      },
    );
  }

  Widget _buildTotalCard(double totalSpent, double percent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[850],
            child: Text(
              "${totalSpent.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "You have spent total",
          style: TextStyle(color: Colors.white),
        ),
        Text(
          "${percent.toStringAsFixed(0)}% of your budget",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Expense List
  Widget _buildExpenseList({required bool showCategory}) {
    if (userId == null) {
      final docs = GuestExpenseStore.expenses;
      if (docs.isEmpty) {
        return const Center(
          child: Text(
            "No expenses yet.",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return _buildList(docs, showCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No expenses yet.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        final docs = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        return _buildList(docs, showCategory);
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> docs, bool showCategory) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final data = docs[i];
        final amt = double.tryParse(data['amount'].toString()) ?? 0;
        final id = data['id'];

        return Slidable(
          key: ValueKey(id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.4,
            children: [
              SlidableAction(
                icon: Icons.edit,
                label: "Edit",
                backgroundColor: Colors.blue,
                onPressed: (_) => _editExpense(data, id),
              ),
              SlidableAction(
                icon: Icons.delete,
                label: "Delete",
                backgroundColor: Colors.red,
                onPressed: (_) => _deleteExpense(id),
              ),
            ],
          ),
          child: Card(
            color: Colors.grey[850],
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 1.5),
            ),
            child: ListTile(
              leading: Icon(
                categoryIcons[data['category']] ?? Icons.category,
                color: Colors.amber,
              ),
              title: Text(
                showCategory
                    ? (data['category'] ?? 'Other')
                    : (data['title'] ?? ''),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                showCategory ? (data['title'] ?? '') : (data['date'] ?? ''),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                amt.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
