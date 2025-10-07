import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Goals/addnewgoal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF0F2027);
const Color kPrimaryDark2 = Color(0xFF203A43);
const Color kPrimaryDark3 = Color(0xFF2C5364);
const Color kCardDark = Color(0xFF1C1C1E);
const Color kAccentColor = Color(0xFFFFA500); // Orange accent
const Color kWhite = Colors.white;
const Color kTextHeading = Colors.white;
const Color kTextSubtitle = Colors.white70;
const Color kTextBody = Colors.white;
const Color kTextSecondary = Colors.white54;

/// Guest goals store
class GuestGoalStore {
  static final List<Map<String, dynamic>> _goals = [];

  static List<Map<String, dynamic>> get goals =>
      List<Map<String, dynamic>>.from(_goals)..sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );

  static void addGoal(Map<String, dynamic> goal) {
    _goals.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...goal,
    });
  }

  static void editGoal(String id, Map<String, dynamic> updatedGoal) {
    final idx = _goals.indexWhere((g) => g['id'] == id);
    if (idx != -1) _goals[idx] = {'id': id, ...updatedGoal};
  }

  static void deleteGoal(String id) {
    _goals.removeWhere((g) => g['id'] == id);
  }

  static double totalCurrent() =>
      _goals.fold(0.0, (sum, g) => sum + (g['current'] ?? 0.0));

  static double monthlyCurrent() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    return _goals.fold(0.0, (sum, g) {
      final createdAt = g['createdAt'] ?? DateTime.now();
      return createdAt.isAfter(firstDay.subtract(const Duration(days: 1)))
          ? sum + (g['current'] ?? 0.0)
          : sum;
    });
  }
}

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

  // Add a variable for user-selected currency, default to $
  String currencySymbol = "";

  @override
  void initState() {
    super.initState();
    _refreshTotals();
  }

  void _refreshTotals() {
    if (currentUser != null) {
      calculateMonthlyAndTotalSavings();
    } else {
      calculateGuestSavings();
    }
  }

  Future<void> calculateMonthlyAndTotalSavings() async {
    if (currentUser == null) return;

    setState(() => isLoading = true);
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);

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
      final createdAt =
          (goal['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      overallTotal += current;
      if (createdAt.isAfter(firstDay.subtract(const Duration(days: 1)))) {
        monthlyTotal += current;
      }
    }

    setState(() {
      monthlySavings = monthlyTotal;
      totalSavings = overallTotal;
      isLoading = false;
    });
  }

  void calculateGuestSavings() {
    setState(() {
      monthlySavings = GuestGoalStore.monthlyCurrent();
      totalSavings = GuestGoalStore.totalCurrent();
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
    return DateFormat('MMMM d, y - h:mm a').format(dateTime);
  }

  void _onAddGoalPressed() async {
    if (isFabLoading) return;
    setState(() => isFabLoading = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Addnewgoal(
          isGuest: currentUser == null,
          onSave: currentUser == null
              ? (goalData) {
                  GuestGoalStore.addGoal(goalData);
                  calculateGuestSavings();
                }
              : null,
        ),
      ),
    );

    if (currentUser != null) {
      await calculateMonthlyAndTotalSavings();
    }

    setState(() => isFabLoading = false);
  }

  Future<void> _editGuestGoal(Map<String, dynamic> goal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Addnewgoal(
          isGuest: true,
          guestGoal: goal,
          onSave: (updatedGoal) {
            GuestGoalStore.editGoal(goal['id'], updatedGoal);
            calculateGuestSavings();
          },
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(String id, {bool isGuest = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardDark,
        title: Text('Delete Goal', style: GoogleFonts.poppins(color: kWhite)),
        content: Text(
            'Are you sure you want to delete this goal?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: kAccentColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (isGuest) {
      GuestGoalStore.deleteGoal(id);
      calculateGuestSavings();
    } else {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('users_goals')
            .doc(id)
            .delete();
        await calculateMonthlyAndTotalSavings();
      }
    }
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
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kPrimaryDark3,
        title: Text(
          'My Saving Goal',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: kWhite,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Center(child: _buildSavingsCard()),
                const SizedBox(height: 16),
                _buildTotalsTile(),
                const SizedBox(height: 12),
                Expanded(
                  child: currentUser == null
                      ? _buildGuestGoalsList()
                      : StreamBuilder<QuerySnapshot>(
                          stream: goalsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: SpinKitCircle(color: kWhite),
                              );
                            }

                            final goals = snapshot.data?.docs ?? [];

                            if (goals.isEmpty) {
                              return Center(
                                child: Text(
                                  'No savings goals yet.\nTap the + button to add one.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, color: Colors.white70),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: goals.length,
                              itemBuilder: (context, index) {
                                final goalDoc = goals[index];
                                final goal =
                                    goalDoc.data() as Map<String, dynamic>;
                                final String title = goal['title'] ?? '';
                                final double current = (goal['current'] ?? 0)
                                    .toDouble();
                                final double target = (goal['target'] ?? 1)
                                    .toDouble();
                                final double progress = (current / target)
                                    .clamp(0.0, 1.0);
                                final createdAt =
                                    (goal['createdAt'] as Timestamp?)
                                            ?.toDate() ??
                                        DateTime.now();

                                return _buildGoalTile(
                                  goalDoc.id,
                                  title,
                                  current,
                                  target,
                                  progress,
                                  createdAt,
                                  () => calculateMonthlyAndTotalSavings(),
                                  firestoreDoc: goalDoc,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white10,
                      blurRadius: 4,
                      offset: Offset(-2, -2),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  tooltip: 'Add Goal',
                  onPressed: _onAddGoalPressed,
                  child: isFabLoading
                      ? const SpinKitFadingCircle(color: kWhite, size: 25)
                      : const Icon(Icons.add_rounded, size: 30, color: kWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestGoalsList() {
    if (GuestGoalStore.goals.isEmpty) {
      return Center(
        child: Text(
          'No savings goals yet in Guest Mode.\nTap the + button to add one.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: GuestGoalStore.goals.length,
      itemBuilder: (context, index) {
        final goal = GuestGoalStore.goals[index];
        final String title = goal['title'] ?? '';
        final double current = goal['current'] ?? 0.0;
        final double target = goal['target'] ?? 1.0;
        final double progress = (current / target).clamp(0.0, 1.0);
        final createdAt = goal['createdAt'] ?? DateTime.now();

        return _buildGoalTile(
          goal['id'],
          title,
          current,
          target,
          progress,
          createdAt,
          () => setState(() => calculateGuestSavings()),
          isGuest: true,
          guestGoalData: goal,
        );
      },
    );
  }

  Widget _buildGoalTile(
    String id,
    String title,
    double current,
    double target,
    double progress,
    DateTime createdAt,
    VoidCallback onUpdate, {
    bool isGuest = false,
    Map<String, dynamic>? guestGoalData,
    DocumentSnapshot? firestoreDoc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (_) async {
                if (isGuest && guestGoalData != null) {
                  _editGuestGoal(guestGoalData);
                } else if (firestoreDoc != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Addnewgoal(
                        goalId: id,
                        existingData: firestoreDoc,
                        isGuest: false,
                      ),
                    ),
                  );
                  await calculateMonthlyAndTotalSavings();
                }
              },
              backgroundColor: kPrimaryDark3,
              foregroundColor: kWhite,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) async {
                await _confirmAndDelete(id, isGuest: isGuest);
              },
              backgroundColor: Colors.red.shade400,
              foregroundColor: kWhite,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kPrimaryDark3.withOpacity(0.5),
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
                  Icon(getGoalIcon(title), color: kWhite),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kTextHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: kPrimaryDark2,
                color: kAccentColor,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                " $currencySymbol ${current.toStringAsFixed(0)} / $currencySymbol ${target.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(color: kTextBody),
              ),
              const SizedBox(height: 4),
              Text(
                "Saved on: ${formatDateTime(createdAt)}",
                style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$currencySymbol ${monthlySavings.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black38,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Monthly Savings",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Track your progress easily",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kPrimaryDark3.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: const Icon(Icons.savings, color: kWhite),
          title: Text(
            "This Month Savings",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: kTextHeading,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            currentUser == null
                ? "Using Guest Mode"
                : "Based on all saved payments",
            style: GoogleFonts.poppins(color: kTextSubtitle, fontSize: 14),
          ),
          trailing: Text(
            "$currencySymbol ${totalSavings.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: kTextHeading,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
