import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/LoginRequriedPage.dart';
import 'package:expanse_tracker_app/Screens/Pages/Goals/addnewgoal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  double monthlySavings = 0.0;
  double totalSavings = 0.0;
  bool isLoading = false;
  bool isFabLoading = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      calculateMonthlyAndTotalSavings();
    } else {
      isLoading = false;
    }
  }

  Future<void> calculateMonthlyAndTotalSavings() async {
    if (currentUser == null) return;

    setState(() => isLoading = true);
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('users_goals')
        .get();

    double monthlyTotal = 0.0;
    double overallTotal = 0.0;

    for (var doc in snapshot.docs) {
      final goal = doc.data();
      final current = (goal['current'] ?? 0).toDouble();
      final createdAt = (goal['createdAt'] as Timestamp?)?.toDate();

      overallTotal += current;

      if (createdAt != null &&
          createdAt.isAfter(firstDay.subtract(const Duration(days: 1)))) {
        monthlyTotal += current;
      }
    }

    setState(() {
      monthlySavings = monthlyTotal;
      totalSavings = overallTotal;
      isLoading = false;
    });
  }

  IconData getGoalIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('bike')) return Icons.pedal_bike;
    if (lower.contains('iphone') || lower.contains('phone'))
      return Icons.phone_iphone;
    if (lower.contains('car')) return Icons.directions_car;
    if (lower.contains('house') || lower.contains('home')) return Icons.home;
    if (lower.contains('travel') || lower.contains('trip'))
      return Icons.flight_takeoff;
    if (lower.contains('education') || lower.contains('study'))
      return Icons.school;
    if (lower.contains('wedding')) return Icons.favorite;
    if (lower.contains('business')) return Icons.business_center;
    return Icons.savings;
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final formatter = DateFormat('MMMM d, y - h:mm a');
    return formatter.format(dateTime);
  }

  void _navigateToLoginRequired() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginRequiredPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot>? goalsStream = currentUser == null
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('users_goals')
              .orderBy('createdAt', descending: true)
              .snapshots();

    return Scaffold(
      // Gradient background for the whole page
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.green,
            title: Text(
              'My Saving Goal',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white, //  BlueGrey
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,

            elevation: 0,
          ),

          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.shade100, // light top
                    Colors.green.shade700,
                  ], // middle],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser == null
                        ? "0"
                        : "${monthlySavings.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.shade100, // light top
                    Colors.green.shade700,
                  ], // middle],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade100.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.savings, color: Colors.black),
                title: const Text(
                  "This Month Savings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  currentUser == null
                      ? "Login to track your savings"
                      : "Based on all saved payments",
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                trailing: Text(
                  currentUser == null
                      ? "0"
                      : "${totalSavings.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: currentUser == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Please login to view and manage your savings goals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _navigateToLoginRequired,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade300,
                          ),
                          child: const Text(
                            'Login Now',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: goalsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SpinKitCircle(color: Colors.green),
                        );
                      }

                      final goals = snapshot.data?.docs ?? [];

                      if (goals.isEmpty) {
                        return const Center(
                          child: Text(
                            'No savings goals yet.\nTap the + button to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final goalDoc = goals[index];
                          final goal = goalDoc.data() as Map<String, dynamic>;
                          final String title = goal['title'] ?? '';
                          final double current = (goal['current'] ?? 0)
                              .toDouble();
                          final double target = (goal['target'] ?? 1)
                              .toDouble();
                          final double progress = (current / target).clamp(
                            0.0,
                            1.0,
                          );
                          final createdAt = (goal['createdAt'] as Timestamp?)
                              ?.toDate();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Slidable(
                              key: ValueKey(goalDoc.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.45,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Addnewgoal(
                                            goalId: goalDoc.id,
                                            existingData: goalDoc,
                                          ),
                                        ),
                                      ).then(
                                        (_) =>
                                            calculateMonthlyAndTotalSavings(),
                                      );
                                    },
                                    backgroundColor: Colors.orange.shade400,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'Edit',
                                  ),
                                  SlidableAction(
                                    onPressed: (_) async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: BorderSide(
                                              color: Colors.orange.shade700,
                                              width: 1,
                                            ),
                                          ),
                                          backgroundColor: Colors.amber.shade50,
                                          title: const Text(
                                            "Delete Goal",
                                            style: TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                          content: const Text(
                                            "Are you sure you want to delete this goal?",
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser!.uid)
                                            .collection('users_goals')
                                            .doc(goalDoc.id)
                                            .delete();
                                        calculateMonthlyAndTotalSavings();
                                      }
                                    },
                                    backgroundColor: Colors.red.shade400,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.greenAccent.shade100, // light top
                                      Colors.green.shade700, // middle
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade700,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade100.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          getGoalIcon(title),
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white,
                                      color: Colors.black12,
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      " ${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Saved on: ${formatDateTime(createdAt)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade300,
        onPressed: () async {
          if (currentUser == null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Addnewgoal()),
            );
            return;
          }

          setState(() => isFabLoading = true);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Addnewgoal()),
          );
          await calculateMonthlyAndTotalSavings();
          setState(() => isFabLoading = false);
        },
        child: isFabLoading
            ? const SpinKitFadingCircle(color: Colors.white, size: 25)
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
