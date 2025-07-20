import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Goals/addnewgoal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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

  @override
  void initState() {
    super.initState();
    calculateMonthlyAndTotalSavings();
  }

  Future<void> calculateMonthlyAndTotalSavings() async {
    setState(() => isLoading = true);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
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
          createdAt.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          createdAt.isBefore(lastDay.add(const Duration(days: 1)))) {
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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final goalsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_goals');

    final Stream<QuerySnapshot> goalsStream = goalsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Saving Goals',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: SpinKitCircle(color: Colors.blue, size: 50.0))
          : Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
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
                          "\$ : ${monthlySavings.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Colors.blue, width: 6),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.savings, color: Colors.blue),
                      title: const Text("This month Savings"),
                      subtitle: const Text("Based on all saved payments"),
                      trailing: Text(
                        "\$ ${totalSavings.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: goalsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final goals = snapshot.data?.docs ?? [];

                      if (goals.isEmpty) {
                        return const Center(
                          child: Text(
                            'No savings goals yet.\nTap the + button to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'Edit',
                                  ),
                                  SlidableAction(
                                    onPressed: (_) async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Delete Goal"),
                                          content: const Text("Are you sure?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await goalsCollection
                                            .doc(goalDoc.id)
                                            .delete();
                                        calculateMonthlyAndTotalSavings();
                                      }
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
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
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[300],
                                      color: Colors.blue,
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "\$ ${current.toStringAsFixed(0)} / \$ ${target.toStringAsFixed(0)}",
                                    ),
                                    if (createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Saved on: ${formatDateTime(createdAt)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
        backgroundColor: Colors.blue,
        onPressed: () async {
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
            : const Icon(Icons.add),
      ),
    );
  }
}
