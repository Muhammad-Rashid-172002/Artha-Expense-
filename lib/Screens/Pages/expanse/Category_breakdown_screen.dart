import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_income/Incomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/addexpanse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

const Color kButtonSecondaryBorder = Colors.blue; // Gold border
const Color kButtonSecondaryText = Color(0xFF1565C0); // Blue text

const Color kButtonDisabled = Color(0xFFBDBDBD); // Gray background
const Color kButtonDisabledText = Color(0xFF757575); // Light gray text

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

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen>
    with TickerProviderStateMixin {
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
        return Colors.green.shade400;
      case 'transport':
        return Colors.teal.shade400;
      case 'shopping':
        return Colors.lightGreen.shade300;
      case 'home':
        return Colors.greenAccent.shade400;
      case 'bills':
        return Colors.lime.shade700;
      case 'health':
        return Colors.green.shade200;
      case 'entertainment':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          elevation: 0,
          title: Text(
            "${widget.category} Expenses",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kAppBarTextColor,
            ),
          ),
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: kAppBarTextColor),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchExpenses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SpinKitCircle(color: kAppBarColor),
                      );
                    }

                    final expenses = snapshot.data ?? [];
                    double spendingRatio = (totalIncome > 0)
                        ? totalAllExpenses / totalIncome
                        : 0.0;

                    return Column(
                      children: [
                        // Income vs Expenses Card
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black26,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    kPrimaryDark1,
                                    kPrimaryDark2,
                                    kPrimaryDark3,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Income vs Expenses",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Decorative line
                                  Container(
                                    height: 2,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white70,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Income:",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        totalIncome.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Expenses:",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        totalAllExpenses.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Spending Overview",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Optional line above progress bar
                                  Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.white30,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: LinearProgressIndicator(
                                      value: spendingRatio.clamp(0.0, 1.0),
                                      minHeight: 12,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.greenAccent,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${(spendingRatio * 100).toStringAsFixed(1)}% of income spent",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Expenses list
                        if (expenses.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                "No expenses in this category.",
                                style: TextStyle(
                                  color: kBodyTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
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

                                return Dismissible(
                                  key: Key(expense['id']),
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kButtonPrimary,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: kButtonPrimaryText,
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      _editExpense(expense);
                                      return false;
                                    } else if (direction ==
                                        DismissDirection.endToStart) {
                                      final shouldDelete = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: const Text(
                                            "Are you sure you want to delete this expense?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (shouldDelete == true) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .collection('users_expenses')
                                            .doc(expense['id'])
                                            .delete();
                                        setState(() {});
                                      }
                                      return shouldDelete;
                                    }
                                    return false;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 400,
                                    ),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kPrimaryDark2.withOpacity(0.85),
                                          kPrimaryDark3.withOpacity(0.85),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                      leading: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: getCategoryColor(
                                          category,
                                        ).withOpacity(0.2),
                                        child: Icon(
                                          categoryIcons[category] ??
                                              Icons.category,
                                          color: getCategoryColor(category),
                                          size: 28,
                                        ),
                                      ),
                                      title: Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        formattedDate,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
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
                                            style: GoogleFonts.poppins(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white60,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        _editExpense(
                                          expense,
                                        ); // Your existing edit function
                                      },
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
