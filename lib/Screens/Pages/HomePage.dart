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
import 'package:google_fonts/google_fonts.dart';
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

  // A Future that will hold the result of the currency loading function.
  late Future<void> _loadCurrencyFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future here
    _loadCurrencyFuture = _loadCurrencySymbol();
    // This can still run independently
    _loadSalaryFromFirebase();
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
    if (currentUser == null) {
      // Handle guest mode for currency
      setState(() {
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
          "iconColor": Colors.black,
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0F7FA), // Light Aqua
                      Color(0xFFB2EBF2), // Soft Mint
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card["amount"],
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
          return const SpinKitFadingCircle(
            color: Color(0xFFB2EBF2),
            size: 40.0,
          );
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
              return const SpinKitFadingCircle(
                color: Color(0xFFB2EBF2),
                size: 40.0,
              );
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
                "iconColor": Colors.black,
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
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE082), // Light Amber
                            Color(0xFFFFCC80), // Soft Orange
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFFFA000),
                          width: 2,
                        ), // Amber border
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFFF8A65), // Orange shadow
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
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card["amount"],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
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
          "No Loan add yet.",
          style: TextStyle(color: Colors.black, fontSize: 16),
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
            child: SpinKitFadingCircle(color: Color(0xFFB2EBF2), size: 40.0),
          );
        }

        final loans = snapshot.data?.docs ?? [];
        if (loans.isEmpty) {
          return const ListTile(
            title: Text(
              "No loans added yet.",
              style: TextStyle(color: Colors.black, fontSize: 16),
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
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF80DEEA),
                  width: 1.5,
                ), // Aqua border
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE082), // Light Amber
                      Color(0xFFFFCC80), // Soft Orange
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFFFFA000),
                    width: 2,
                  ), // Amber border
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFF8A65), // Orange shadow
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Color(0xFFFFA000), // Medium Amber
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Amount: $amount\nDate: $formattedDate",
                    style: const TextStyle(color: Colors.black54),
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
                        color: status == 'Paid'
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 248, 222, 137),
            ], //  Gradient background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    title: Text(
                      'Overview',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F), //  BlueGrey
                        letterSpacing: 1.2,
                      ),
                    ),
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            const Color.fromARGB(
                              255,
                              254,
                              217,
                              96,
                            ), // light amber
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    iconTheme: const IconThemeData(
                      color: Colors.black87,
                    ), // for back button
                    elevation: 0,
                  ),
                  // Calendar Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF80DEEA),
                        width: 1.5,
                      ), // Aqua border
                    ),
                    elevation: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD54F), // Soft Amber
                            Color(0xFFFFB74D), // Light Orange
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(4, 6),
                          ),
                        ],
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
                              color: Colors.black87, // readable on light bg
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
                                    color:
                                        Colors.amber.shade700, // Teal highlight
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        daysOfWeek[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${currentDay.day}',
                                        style: const TextStyle(
                                          color: Colors.white,
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

                  const SizedBox(height: 20),

                  // The updated section using FutureBuilder
                  FutureBuilder(
                    future: _loadCurrencyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SpinKitFadingCircle(
                          color: Color(0xFFB2EBF2),
                          size: 40.0,
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading currency."),
                        );
                      }
                      return buildIncomeExpenseStream();
                    },
                  ),
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
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFB300), // Amber
                                        Color(0xFFFF7043), // Deep Orange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE082), // Light Amber
                                        Color(0xFFFFCC80), // Soft Orange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00838F)
                                    : const Color(0xFF80DEEA),
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
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card["title"],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
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

                  Row(
                    children: [
                      Text(
                        'Your Loans:',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(height: 300, child: buildLoanListTile()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
