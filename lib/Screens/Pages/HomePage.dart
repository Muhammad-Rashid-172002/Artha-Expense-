import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_income/Incomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/Loanscreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/reminder.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/saving.dart';
import 'package:expanse_tracker_app/model/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/montlybudget.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Guest Income Store (Local)

class GuestStore {
  static ValueNotifier<List<Map<String, dynamic>>> incomes = ValueNotifier([]);
  static ValueNotifier<List<Map<String, dynamic>>> expenses = ValueNotifier([]);

  static double get totalIncome =>
      incomes.value.fold(0.0, (sum, item) => sum + (item['amount'] as double));

  static double get totalExpense =>
      expenses.value.fold(0.0, (sum, item) => sum + (item['amount'] as double));

  static void addIncome(double amount) {
    incomes.value = [
      ...incomes.value,
      {'amount': amount},
    ];
  }

  static void addExpense(double amount) {
    expenses.value = [
      ...expenses.value,
      {'amount': amount},
    ];
  }
}

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

  late Future<void> _loadCurrencyFuture;
  bool _isHidden = false;
  final formatter = NumberFormat.currency(symbol: "", decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadCurrencyFuture = _loadCurrencySymbol();
    _loadSalaryFromFirebase();
  }

  Future<void> _loadSalaryFromFirebase() async {
    if (currentUser == null) {
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
          currencySymbol = doc.data()?['currencySymbol'] ?? '\$';
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

  void _showAddIncomeExpenseSheet(String type) {
    if (type == "Income") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncomeScreen(
            isGuest: currentUser == null,
            onIncomeAdded: (income) {
              setState(() {
                GuestStore.addIncome(income['amount']);
              });
            },
          ),
        ),
      ).then((_) => setState(() {}));
    } else if (type == "Expense") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExpenseScreen(
            isGuest: currentUser == null,
            onExpenseAdded: (expense) {
              setState(() {
                GuestStore.addExpense(expense['amount']);
              });
            },
          ),
        ),
      ).then((_) => setState(() {}));
    }
  }

  /// ================================
  /// Income/Expense Stream + Guest UI
  /// ================================
  Widget buildIncomeExpenseStream() {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    if (currentUser == null) {
      // GUEST MODE
      totalExpense = GuestExpenseStore.expenses.fold(
        0.0,
        (first, second) => first + second['amount'] as double,
      );

      print("Total Expense: $totalExpense");
      totalIncome = GuestIncomeStore.incomes.fold(
        0.0,
        (sum, item) => sum + (item['amount'] as double),
      );

      double balance = totalIncome - totalExpense;

      return Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: Column(
          children: [
            _buildBalanceCard(totalIncome, totalExpense),
            const SizedBox(height: 10),
            _buildMainCards([
              {
                "title": "Income",
                "amount": "$currencySymbol${formatter.format(totalIncome)}",
                "icon": Icons.arrow_upward,
                "iconColor": Colors.green,
              },
              {
                "title": "Expense",
                "amount": "$currencySymbol${formatter.format(totalExpense)}",
                "icon": Icons.arrow_downward,
                "iconColor": Colors.red,
              },
              {
                "title": "Budget",
                "amount": "$currencySymbol${formatter.format(balance)}",
                "icon": Icons.pie_chart,
                "iconColor": Colors.black,
              },
            ]),
          ],
        ),
      );
    }

    // LOGGED-IN USER MODE
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid ?? "guest")
          .collection('users_income')
          .snapshots(),
      builder: (context, incomeSnapshot) {
        if (!incomeSnapshot.hasData) {
          return const SpinKitFadingCircle(
            color: Color(0xFF424242),
            size: 40.0,
          );
        }

        totalIncome = incomeSnapshot.data!.docs.fold(0.0, (sum, doc) {
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
                color: Color(0xFF424242),
                size: 40.0,
              );
            }

            totalExpense = expenseSnapshot.data!.docs.fold(0.0, (sum, doc) {
              final amount = doc['amount'];
              return sum + (amount is num ? amount.toDouble() : 0.0);
            });

            double balance = totalIncome - totalExpense;

            final List<Map<String, dynamic>> mainCards = [
              {
                "title": "Income",
                "amount": "$currencySymbol${formatter.format(totalIncome)}",
                "icon": Icons.arrow_upward,
                "iconColor": Colors.green,
              },
              {
                "title": "Expense",
                "amount": "$currencySymbol${formatter.format(totalExpense)}",
                "icon": Icons.arrow_downward,
                "iconColor": Colors.red,
              },
              {
                "title": "Budget",
                "amount": "$currencySymbol${formatter.format(balance)}",
                "icon": Icons.pie_chart,
                "iconColor": Colors.blue,
              },
            ];

            return Column(
              children: [
                _buildBalanceCard(totalIncome, totalExpense),
                const SizedBox(height: 10),
                _buildMainCards(mainCards),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(double totalIncome, double totalExpense) {
    double balance = totalIncome - totalExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1F26), Color(0xFF2C313C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Top Row (Title + Visibility Button) =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Available Balance",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isHidden = !_isHidden);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isHidden
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ===== Balance =====
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _isHidden
                            ? "•••••"
                            : "$currencySymbol${formatter.format(balance)}",
                        key: ValueKey(_isHidden),
                        style: GoogleFonts.robotoMono(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0
                              ? Colors.greenAccent.shade400
                              : Colors.redAccent.shade200,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ===== Income / Expense Summary =====
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          title: "Income",
                          amount: totalIncome,
                          gradientColors: const [
                            Color(0xFF00C853),
                            Color(0xFF2E7D32),
                          ],
                          icon: Icons.arrow_downward_rounded,
                          iconColor: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatBox(
                          title: "Expense",
                          amount: totalExpense,
                          gradientColors: const [
                            Color(0xFFD32F2F),
                            Color(0xFF880E4F),
                          ],
                          icon: Icons.arrow_upward_rounded,
                          iconColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Small reusable stat boxes (Income / Expense)
  Widget _buildStatBox({
    required String title,
    required double amount,
    required List<Color> gradientColors,
    required IconData icon,
    required Color iconColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isHidden
                      ? "•••••"
                      : "$currencySymbol${formatter.format(amount)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCards(List<Map<String, dynamic>> mainCards) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: mainCards.map((card) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (card["title"] == "Income" || card["title"] == "Expense") {
                _showAddIncomeExpenseSheet(card["title"]);
              } else {
                _navigateToScreen(card["title"]);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: card["title"] == "Income"
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF0F2027),
                          Color(0xFF203A43),
                          Color(0xFF2C5364),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : card["title"] == "Expense"
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF2C5364),
                          Color(0xFF203A43),
                          Color(0xFF0F2027),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1C1C1C), Color(0xFF2E2E2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(card["icon"], size: 30, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    "Add ${card["title"]}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> smallCards = [
      {"title": "Saving", "icon": Icons.savings},
      {"title": "Reminder", "icon": Icons.alarm},
      {"title": "Loan", "icon": Icons.credit_card},
    ];

    // String _getGreetingMessage() {
    //   final hour = DateTime.now().hour;
    //   if (hour < 12) {
    //     return "Good Morning ☀️";
    //   } else if (hour < 17) {
    //     return "Good Afternoon 🌤️";
    //   } else {
    //     return "Good Evening 🌙";
    //   }
    // }

    String _getFormattedDate() {
      final now = DateTime.now();
      return "${now.day}/${now.month}/${now.year}";
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              expandedHeight: 120,
              collapsedHeight: kToolbarHeight,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: kPrimaryGradient, // matches your dark theme
                ),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 14,
                  ),
                  title: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String name = 'User';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        name = data['name'] ?? 'User';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Hi, $name",
                            style: GoogleFonts.poppins(
                              fontSize: 16, // smaller font
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Welcome back",
                            style: GoogleFonts.poppins(
                              fontSize: 14, // smaller subtitle font
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      FutureBuilder(
                        future: _loadCurrencyFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SpinKitCircle(color: Color(0xFF424242)),
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

                                switch (card['title']) {
                                  case 'Saving':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Savings(),
                                      ),
                                    );
                                    break;
                                  case 'Reminder':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Reminderscreen(),
                                      ),
                                    );
                                    break;
                                  case 'Loan':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Loanscreen(),
                                      ),
                                    );
                                    break;
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2C5364)
                                      : const Color(0xFF203A43),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      card['icon'],
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      card['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> transactions = [];
}
