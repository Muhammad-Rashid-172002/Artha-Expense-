import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/TaskPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/Incomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/Loanscreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/reminder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/montlybudget.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double totalSalary = 0.0;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double monthlyBudget = 0.0;
  int selectedSmallCardIndex = -1;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  String currencySymbol = "";
  String currencyFlag = "";
  @override
  void initState() {
    super.initState();
    _loadSalaryFromFirebase();
    _calculateTotalIncome();
    _calculateTotalExpense();
  }

  Future<void> _loadCurrencySymbol() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          currencySymbol = doc.data()?['currencySymbol'] ?? '';
          currencyFlag = doc.data()?['currencyFlag'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading currency: $e");
    }
  }

  Future<void> _loadSalaryFromFirebase() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('salary')) {
        setState(() {
          totalSalary = (doc['salary'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error loading salary: $e");
    }
  }

  Future<void> _calculateTotalIncome() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('users_income')
          .get();
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }
      setState(() {
        totalIncome = total;
        monthlyBudget = totalIncome - totalExpense;
      });
    } catch (e) {
      debugPrint("Error calculating income: $e");
    }
  }

  Future<void> _calculateTotalExpense() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('users_expenses')
          .get();
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }
      setState(() {
        totalExpense = total;
        monthlyBudget = totalIncome - totalExpense;
      });
    } catch (e) {
      debugPrint("Error calculating expenses: $e");
    }
  }

  void _navigateToScreen(String title) {
    if (title == "Total Expense") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExpenseScreen()),
      );
    } else if (title == "Monthly Budget") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BudgetScreen()),
      );
    }
  }

  Widget buildLoanListTile() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('users_loans')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitFadingCircle(color: Colors.white, size: 40.0),
          );
        }

        final loans = snapshot.data?.docs ?? [];
        if (loans.isEmpty) {
          return const ListTile(title: Text("No loans added yet."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "Your Loans",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...loans.map((doc) {
              final name = doc['name'] ?? '';
              final amount =
                  (doc['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final date = (doc['createdAt'] as Timestamp).toDate();
              final status = (doc['status'] ?? 'Pending')
                  .toString(); // Default to Pending
              final formattedDate = DateFormat(
                'dd MMM yyyy – hh:mm a',
              ).format(date);

              return Card(
                color: Colors.grey[850], // Card background color
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.white, // Border color
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white, // Text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Amount: $amount\nDate: $formattedDate",
                    style: const TextStyle(
                      color: Colors.white70,
                    ), // Subtitle text color
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'Paid'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Paid' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverspending = totalExpense >= totalIncome;
    final bool isHighSpending = totalExpense >= (totalIncome * 0.75);

    final List<Map<String, dynamic>> mainCards = [
      {
        "title": "Total Income",
        "amount":
            "${currencyFlag.isNotEmpty ? "$currencyFlag " : ""}${currencySymbol}${totalIncome.toStringAsFixed(2)}",
        "icon": Icons.arrow_upward,
        "iconColor": Colors.green,
      },
      {
        "title": "Total Expense",
        "amount":
            "${currencyFlag.isNotEmpty ? "$currencyFlag " : ""}${currencySymbol}${totalExpense.toStringAsFixed(2)}",
        "icon": isOverspending || isHighSpending
            ? Icons.arrow_downward
            : Icons.arrow_upward,
        "iconColor": isOverspending
            ? Colors.red
            : isHighSpending
            ? Colors.red
            : Colors.green,
      },
      {
        "title": "Monthly Budget",
        "amount":
            "${currencyFlag.isNotEmpty ? "$currencyFlag " : ""}${currencySymbol}${monthlyBudget.toStringAsFixed(2)}",
        "icon": Icons.pie_chart,
        "iconColor": Colors.white,
      },
    ];

    final List<Map<String, dynamic>> smallCards = [
      {"title": "Saving", "icon": Icons.savings},
      {"title": "Reminder", "icon": Icons.alarm},
      {"title": "Loan", "icon": Icons.credit_card},
    ];

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // default is true, but set it just in case
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCircle(color: Colors.white, size: 40.0),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadSalaryFromFirebase();
                  await _calculateTotalIncome();
                  await _calculateTotalExpense();
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Calendar Card
                          Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            color: Colors.grey[850],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white, // Border color
                                width: 2, // Border width
                              ),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMMM yyyy',
                                    ).format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
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
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: mainCards.map((card) {
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (card["title"] == "Total Income") {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const IncomeScreen(),
                                        ),
                                      );
                                    } else {
                                      _navigateToScreen(card["title"]);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          card["icon"],
                                          size: 30,
                                          color:
                                              card["iconColor"] ?? Colors.white,
                                        ),

                                        Text(
                                          card["title"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          card["amount"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: List.generate(smallCards.length, (index) {
                              final card = smallCards[index];
                              final isSelected =
                                  selectedSmallCardIndex == index;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSmallCardIndex = index;
                                    });
                                    switch (card['title']) {
                                      case 'Saving':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const TaskPage(),
                                          ),
                                        );
                                        break;
                                      case 'Reminder':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const Reminderscreen(),
                                          ),
                                        );
                                        break;
                                      case 'Loan':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const Loanscreen(),
                                          ),
                                        );
                                        break;
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.amber[850]
                                          : Colors.grey[850],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.amber,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade300,
                                          blurRadius: 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          card["icon"],
                                          size: 30,
                                          color: isSelected
                                              ? Colors.grey[850]
                                              : Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          card["title"],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.grey[850]
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          child: buildLoanListTile(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
