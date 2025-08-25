// Paste this import section at the top of the file
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/Incomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/Loanscreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/reminder.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/saving.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/montlybudget.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String currencySymbol = "";
  String currencyFlag = "";
  double totalSalary = 0.0;
  int selectedSmallCardIndex = -1;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSalaryFromFirebase();
    _loadCurrencySymbol();
  }

  Future<void> _loadSalaryFromFirebase() async {
    if (currentUser == null) {
      // Guest mode: Set defaults
      setState(() {
        totalSalary = 0.0;
        currencySymbol = '\$';
        currencyFlag = '';
      });
      return;
    }

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

  void _navigateToScreen(String title) {
    if (title == "Expense") {
      if (currentUser == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginRequiredPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExpenseScreen()),
        );
      }
    } else if (title == "Budget") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BudgetScreen()),
      );
    }
  }

  Widget buildIncomeExpenseStream() {
    // For guest users, use default values
    if (currentUser == null) {
      final List<Map<String, dynamic>> mainCards = [
        {
          "title": "Income",
          "amount": "0.00",
          "icon": Icons.arrow_upward,
          "iconColor": Colors.green,
        },
        {
          "title": "Expense",
          "amount": "0.00",
          "icon": Icons.arrow_downward,
          "iconColor": Colors.red,
        },
        {
          "title": "Budget",
          "amount": "0.00",
          "icon": Icons.pie_chart,
          "iconColor": Colors.white,
        },
      ];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: mainCards.map((card) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (card["title"] == "Income") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncomeScreen()),
                  );
                } else if (card["title"] == "Expense") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                  );
                } else if (card["title"] == "Budget") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BudgetScreen()),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(card["icon"], size: 30, color: card["iconColor"]),
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
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // For logged in users, keep the existing stream builder logic
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid ?? "guest")
          .collection('users_income')
          .snapshots(),
      builder: (context, incomeSnapshot) {
        if (!incomeSnapshot.hasData) {
          return const SpinKitFadingCircle(color: Colors.white, size: 40.0);
        }

        double totalIncome = incomeSnapshot.data!.docs.fold(0.0, (sum, doc) {
          final amount = doc['amount'];
          return sum + (amount is num ? amount.toDouble() : 0.0);
        });

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid ?? "guest")
              .collection('users_expenses')
              .snapshots(),
          builder: (context, expenseSnapshot) {
            if (!expenseSnapshot.hasData) {
              return const SpinKitFadingCircle(color: Colors.white, size: 40.0);
            }

            double totalExpense = expenseSnapshot.data!.docs.fold(0.0, (
              sum,
              doc,
            ) {
              final amount = doc['amount'];
              return sum + (amount is num ? amount.toDouble() : 0.0);
            });

            double monthlyBudget = totalIncome - totalExpense;
            final bool isOverspending = totalExpense >= totalIncome;
            final bool isHighSpending = totalExpense >= (totalIncome * 0.75);

            final List<Map<String, dynamic>> mainCards = [
              {
                "title": "Income",
                "amount":
                    "${currencyFlag.isNotEmpty ? "$currencyFlag " : ""}${currencySymbol}${totalIncome.toStringAsFixed(2)}",
                "icon": Icons.arrow_upward,
                "iconColor": Colors.green,
              },
              {
                "title": "Expense",
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
                "title": "Budget",
                "amount":
                    "${currencyFlag.isNotEmpty ? "$currencyFlag " : ""}${currencySymbol}${monthlyBudget.toStringAsFixed(2)}",
                "icon": Icons.pie_chart,
                "iconColor": Colors.white,
              },
            ];

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: mainCards.map((card) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (card["title"] == "Income") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeScreen(),
                          ),
                        );
                      } else {
                        _navigateToScreen(card["title"]);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            card["icon"],
                            size: 30,
                            color: card["iconColor"],
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
            );
          },
        );
      },
    );
  }

  Widget buildLoanListTile() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          "Login to view and manage your loans.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

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
          return const ListTile(
            title: Text(
              "No loans added yet.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final doc = loans[index];
            final name = doc['name'] ?? '';
            final amount =
                (doc['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
            final date = (doc['createdAt'] as Timestamp).toDate();
            final status = (doc['status'] ?? 'Pending').toString();
            final formattedDate = DateFormat(
              'dd MMM yyyy – hh:mm a',
            ).format(date);

            return Card(
              color: Colors.grey[850],
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Amount: $amount\nDate: $formattedDate",
                  style: const TextStyle(color: Colors.white70),
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> smallCards = [
      {"title": "Saving", "icon": Icons.savings},
      {"title": "Reminder", "icon": Icons.alarm},
      {"title": "Loan", "icon": Icons.credit_card},
    ];

    return Scaffold(
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Calendar Card
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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

                            if (isToday) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${currentDay.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
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

                const SizedBox(height: 20),

                buildIncomeExpenseStream(),
                const SizedBox(height: 20),

                Row(
                  children: List.generate(smallCards.length, (index) {
                    final card = smallCards[index];
                    final isSelected = selectedSmallCardIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSmallCardIndex = index;
                          });

                          // Allow guest users to access Saving, Reminder, Loan
                          if (currentUser == null &&
                              (card['title'] != 'Saving' &&
                                  card['title'] != 'Reminder' &&
                                  card['title'] != 'Loan')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginRequiredPage(),
                              ),
                            );
                            return;
                          }

                          // Navigate to the selected screen
                          switch (card['title']) {
                            case 'Saving':
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => Savings()),
                              );
                              break;
                            case 'Reminder':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Reminderscreen(),
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
                            default:
                              // Fallback (only goes here if another card is added in future)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginRequiredPage(),
                                ),
                              );
                          }
                        },

                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber[850]
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.amber,
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

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(height: 300, child: buildLoanListTile()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
