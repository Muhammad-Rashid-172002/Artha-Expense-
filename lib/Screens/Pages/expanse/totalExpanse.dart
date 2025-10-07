import 'package:expanse_tracker_app/Screens/Pages/Update_income/Incomescreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addexpanse.dart';

// ==== COLORS ====
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

/// Temporary storage for guest expenses
class GuestExpenseStore {
  static final List<Map<String, dynamic>> _expenses = [];

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
  final bool isGuest;
  final void Function(Map<String, dynamic> expense)? onExpenseAdded;

  const ExpenseScreen({super.key, this.isGuest = false, this.onExpenseAdded});

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
      final newExpense = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": result["title"],
        "category": result["category"],
        "amount": result["amount"],
        "date": result["date"],
      };
      GuestExpenseStore.addExpense(newExpense);
    }

    setState(() {});
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            "Total Expenses",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kAppBarTextColor,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarTextColor),
            onPressed: () => Navigator.pop(context),
          ),

          elevation: 0,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildCalendar(),
                  _buildTotalSpent(),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 192, 21, 21),
                          Color.fromARGB(255, 182, 13, 25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.05,
                        ), // translucent glass effect
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        tabs: const [
                          Tab(text: "Spends"),
                          Tab(text: "Categories"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildExpenseList(showCategory: false),
              _buildExpenseList(showCategory: true),
            ],
          ),
        ),
        // AddExpense,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF416C), // Bright Red-Pink
                Color(0xFFFF4B2B), // Deep Red-Orange
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FF4B2B), // Soft red glow
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor:
                Colors.transparent, // Gradient handled by parent container
            tooltip: 'Add Expenses',
            onPressed: _onAddExpense,
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          // Match background tone with transparency for depth
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==== Month Header ====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(today),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ==== Week Days ====
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(7, (index) {
                    final currentDay = startOfWeek.add(Duration(days: index));
                    final isToday =
                        today.day == currentDay.day &&
                        today.month == currentDay.month &&
                        today.year == currentDay.year;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 58, 87, 235),
                                    Color.fromARGB(255, 115, 112, 235),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isToday
                              ? null
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? Colors.white.withOpacity(0.8)
                                : Colors.white24,
                            width: 1.2,
                          ),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              daysOfWeek[index],
                              style: TextStyle(
                                color: isToday ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${currentDay.day}',
                              style: TextStyle(
                                color: isToday ? Colors.black : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSpent() {
    final gradientColors = [const Color(0xFF00C6FF), const Color(0xFF0072FF)];

    Widget _buildAnimatedCard(double totalSpent, double percent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white12, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== Title ====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Total Spent",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.pie_chart_rounded, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 18),

                // ==== Progress Bar ====
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 12,
                      width:
                          MediaQuery.of(context).size.width *
                          (percent.clamp(0, 100) / 100) *
                          0.85,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: percent >= 80
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ==== Text Info ====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${totalSpent.toStringAsFixed(2)} spent",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${percent.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 16,
                        color: percent >= 80
                            ? Colors.redAccent
                            : Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ===== Guest Mode =====
    if (userId == null) {
      double totalSpent = GuestExpenseStore.expenses.fold(
        0.0,
        (sum, exp) => sum + (exp['amount'] ?? 0),
      );
      double percent = budget == 0
          ? 0.0
          : ((totalSpent / budget) * 100).clamp(0, 100).toDouble();

      return _buildAnimatedCard(totalSpent, percent);
    }

    // ===== Firebase Stream =====
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          );
        }

        double totalSpent = 0.0;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            totalSpent +=
                double.tryParse((doc['amount'] ?? '0').toString()) ?? 0.0;
          }
        }

        double percent = budget == 0
            ? 0.0
            : ((totalSpent / budget) * 100).clamp(0, 100).toDouble();

        return _buildAnimatedCard(totalSpent, percent);
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
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: kBalanceCardColor,
            child: Text(
              "${totalSpent.toStringAsFixed(0)}",
              style: const TextStyle(
                color: kBalanceCardTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "You have spent total",
          style: TextStyle(color: kBodyTextColor, fontSize: 16),
        ),
        Text(
          "${percent.toStringAsFixed(0)}% of your budget",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kButtonPrimary,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExpenseList({required bool showCategory}) {
    if (userId == null) {
      final docs = GuestExpenseStore.expenses;
      if (docs.isEmpty) {
        return const Center(
          child: Text(
            "No expenses yet.",
            style: TextStyle(color: kButtonPrimary),
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
              style: TextStyle(color: kButtonPrimary),
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
                backgroundColor: kButtonPrimary,
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: kPrimaryDark2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1F26), Color(0xFF2A2F3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white10,
                    blurRadius: 3,
                    offset: Offset(-2, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ==== Left: Icon + Details ====
                  Row(
                    children: [
                      // Icon container with soft gradient background
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F2027), Color(0xFF203A43)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          categoryIcons[data['category']] ??
                              Icons.shopping_bag_rounded,
                          color: Colors.redAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // ==== Title + Date ====
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showCategory
                                ? (data['category'] ?? 'Other')
                                : (data['title'] ?? ''),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            showCategory
                                ? (data['title'] ?? '')
                                : (data['date'] ?? ''),
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ==== Right: Amount ====
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '-${amt.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
