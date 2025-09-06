import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addexpanse.dart';

/// Temporary storage for guest expenses
class GuestExpenseStore {
  static final List<Map<String, dynamic>> _expenses = [];

  /// Get sorted list (latest first)
  static List<Map<String, dynamic>> get expenses =>
      List<Map<String, dynamic>>.from(_expenses)..sort((a, b) {
        final da = DateFormat("dd MMM yyyy").parse(a["date"]);
        final db = DateFormat("dd MMM yyyy").parse(b["date"]);
        return db.compareTo(da);
      });

  static void addExpense(Map<String, dynamic> expense) {
    _expenses.add(expense);
  }

  static void deleteExpense(String id) {
    _expenses.removeWhere((exp) => exp["id"] == id);
  }

  static void editExpense(String id, Map<String, dynamic> updatedExpense) {
    final index = _expenses.indexWhere((exp) => exp["id"] == id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (result != null && userId == null) {
      // Guest mode → Save locally
      final newExpense = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": result["title"],
        "category": result["category"],
        "amount": result["amount"],
        "date": result["date"],
      };
      GuestExpenseStore.addExpense(newExpense);
    }

    setState(() {}); // refresh UI after returning
  }

  Future<void> _editExpense(Map<String, dynamic> data, String id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(existingData: data, docId: id),
      ),
    );

    if (result != null && userId == null) {
      GuestExpenseStore.editExpense(id, {
        "id": id,
        "title": result["title"],
        "category": result["category"],
        "amount": result["amount"],
        "date": result["date"],
      });
    }

    setState(() {});
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
      setState(() => GuestExpenseStore.deleteExpense(id));
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
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 248, 222, 137)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildCalendar(),
              _buildTotalSpent(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.greenAccent, Colors.green],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.deepOrange,
                  tabs: const [
                    Tab(text: "Spends"),
                    Tab(text: "Categories"),
                  ],
                ),
              ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddExpense,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Calendar widget
  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF80DEEA), width: 1.5),
        ),
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final today = DateTime.now();
                  final startOfWeek = today.subtract(
                    Duration(days: today.weekday - 1),
                  );
                  final currentDay = startOfWeek.add(Duration(days: index));
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

                  if (isToday) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            daysOfWeek[index],
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currentDay.day}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        Text(
                          daysOfWeek[index],
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${currentDay.day}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }
                }),
              ),
            ],
          ),
        ),
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
            backgroundColor: Colors.green[100],
            child: Text(
              "${totalSpent.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "You have spent total",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        Text(
          "${percent.toStringAsFixed(0)}% of your budget",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
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
            style: TextStyle(color: Colors.green),
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
              style: TextStyle(color: Colors.green),
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
            color: Colors.green[100],
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.green, width: 1.5),
            ),
            child: ListTile(
              leading: Icon(
                categoryIcons[data['category']] ?? Icons.category,
                color: Colors.green,
              ),
              title: Text(
                showCategory
                    ? (data['category'] ?? 'Other')
                    : (data['title'] ?? ''),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                showCategory ? (data['title'] ?? '') : (data['date'] ?? ''),
                style: TextStyle(color: Colors.grey[700]),
              ),
              trailing: Text(
                amt.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 14, 174, 19),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
