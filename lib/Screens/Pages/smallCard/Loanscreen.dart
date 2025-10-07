// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Goals/addnewgoal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ==== COLOR CONSTANTS ====
const Color kAppBarColor = Color(0xFF1565C0); // Deep Blue
const Color kAppBarTextColor = Colors.white;

const Color kBalanceCardColor = Color(0xFFFFD700); // Gold
const Color kCardTextColor = Colors.black87;
const Color kBodyTextColor = Colors.black54;

const Color kButtonPrimary = Color(0xFF1565C0);
const Color kButtonPrimaryText = Colors.white;
const Color kButtonSecondaryBorder = Color(0xFFFFD700);

// ====== GUEST LOAN STORAGE ======
class GuestLoanStore {
  static final List<Map<String, dynamic>> _loans = [];

  static List<Map<String, dynamic>> get loans =>
      List<Map<String, dynamic>>.from(_loans)..sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );

  static void addLoan({
    required String name,
    required double amount,
    required String status,
    required DateTime createdAt,
  }) {
    _loans.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
    });
  }

  static void editLoan({
    required String id,
    required String name,
    required double amount,
    required String status,
    required DateTime createdAt,
  }) {
    final idx = _loans.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _loans[idx] = {
        'id': id,
        'name': name,
        'amount': amount,
        'status': status,
        'createdAt': createdAt,
      };
    }
  }

  static void deleteLoan(String id) {
    _loans.removeWhere((r) => r['id'] == id);
  }
}

// ====== LOAN SCREEN ======
class Loanscreen extends StatefulWidget {
  const Loanscreen({super.key});

  @override
  State<Loanscreen> createState() => _LoanscreenState();
}

class _LoanscreenState extends State<Loanscreen> {
  final user = FirebaseAuth.instance.currentUser;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showNotification(String loanName) async {
    const androidDetails = AndroidNotificationDetails(
      'loan_channel_id',
      'Loan Notifications',
      channelDescription: 'Notifications for overdue loans',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Loan Overdue 🚨',
      'Loan "$loanName" is now overdue!',
      notificationDetails,
    );
  }

  Stream<QuerySnapshot>? getUserLoans() {
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('users_loans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy – hh:mm a').format(date);

  Future<void> markOverdue(DocumentSnapshot doc) async {
    if (user == null) return;
    final createdAt = (doc['createdAt'] as Timestamp).toDate();
    final status = doc['status'] ?? 'Pending';

    if (status == 'Pending' &&
        DateTime.now().difference(createdAt).inDays > 30) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('users_loans')
          .doc(doc.id)
          .update({'status': 'Overdue'});
      await showNotification(doc['name']);
    }
  }

  Future<void> deleteLoan(String loanId, {bool isGuest = false}) async {
    if (isGuest) {
      setState(() {
        GuestLoanStore.deleteLoan(loanId);
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('users_loans')
          .doc(loanId)
          .delete();
    }
  }

  Future<void> showDeleteConfirmationDialog(
    String loanId, {
    bool isGuest = false,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Delete Loan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this loan?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await deleteLoan(loanId, isGuest: isGuest);
    }
  }

  Future<void> showLoanBottomSheet({
    DocumentSnapshot? existingLoan,
    Map<String, dynamic>? guestLoan,
  }) async {
    final nameController = TextEditingController(
      text: existingLoan != null
          ? existingLoan['name']
          : guestLoan != null
          ? guestLoan['name']
          : '',
    );
    final amountController = TextEditingController(
      text: existingLoan != null
          ? (existingLoan['amount'] as num).toString()
          : guestLoan != null
          ? (guestLoan['amount'] as num).toString()
          : '',
    );
    String status = existingLoan != null
        ? existingLoan['status']
        : guestLoan != null
        ? guestLoan['status']
        : 'Pending';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setStateSB) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==== Title ====
                        Text(
                          existingLoan == null && guestLoan == null
                              ? "Add Loan"
                              : "Edit Loan",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ==== Name Field ====
                        _buildGlassTextField(
                          controller: nameController,
                          label: "Name",
                          icon: Icons.person,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 10),

                        // ==== Amount Field ====
                        _buildGlassTextField(
                          controller: amountController,
                          label: "Amount",
                          icon: Icons.attach_money, // money icon
                          keyboardType: TextInputType.number,
                          fillColor: Colors.white.withOpacity(
                            0.1,
                          ), // glassy effect
                        ),

                        const SizedBox(height: 10),

                        // ==== Status Dropdown ====
                        DropdownButtonFormField<String>(
                          value: status,
                          dropdownColor: kPrimaryDark2,
                          style: GoogleFonts.poppins(color: Colors.white),
                          items: ["Pending", "Paid"].map((val) {
                            return DropdownMenuItem(
                              value: val,
                              child: Text(
                                val,
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setStateSB(() => status = val!),
                          decoration: InputDecoration(
                            labelText: "Status",
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ==== Save Button ====
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final amount = double.tryParse(
                                amountController.text.trim(),
                              );

                              if (name.isEmpty ||
                                  amount == null ||
                                  amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "⚠️ Please enter valid name and amount",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (user == null) {
                                if (guestLoan == null) {
                                  GuestLoanStore.addLoan(
                                    name: name,
                                    amount: amount,
                                    status: status,
                                    createdAt: DateTime.now(),
                                  );
                                } else {
                                  GuestLoanStore.editLoan(
                                    id: guestLoan['id'],
                                    name: name,
                                    amount: amount,
                                    status: status,
                                    createdAt: guestLoan['createdAt'],
                                  );
                                }
                                setState(() {});
                              } else {
                                final loanRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user!.uid)
                                    .collection('users_loans');

                                if (existingLoan == null) {
                                  await loanRef.add({
                                    'name': name,
                                    'amount': amount,
                                    'status': status,
                                    'createdAt': DateTime.now(),
                                  });
                                } else {
                                  await loanRef.doc(existingLoan.id).update({
                                    'name': name,
                                    'amount': amount,
                                    'status': status,
                                  });
                                }
                              }

                              Navigator.pop(context);
                            },
                            child: Text(
                              "Save",
                              style: GoogleFonts.poppins(
                                color: kButtonPrimaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon, // optional icon
    Color fillColor = const Color.fromRGBO(
      255,
      255,
      255,
      0.1,
    ), // default glassy fill
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(color: Colors.white70),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.tealAccent.shade200)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loansStream = getUserLoans();

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
          foregroundColor: kAppBarTextColor,
          backgroundColor: Colors.transparent,
          title: Text(
            'Loan List',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kAppBarTextColor,
            ),
          ),
          centerTitle: true,
        ),
        body: user == null
            ? GuestLoanStore.loans.isEmpty
                  ? Center(
                      child: Text(
                        "No loans added yet. (Guest Mode)",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    )
                  : buildLoanList(GuestLoanStore.loans, isGuest: true)
            : StreamBuilder<QuerySnapshot>(
                stream: loansStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SpinKitCircle(color: Colors.black),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No loans added yet.",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }

                  return buildLoanList(snapshot.data!.docs, isGuest: false);
                },
              ),

        //showLoanBottomSheet(),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 12,
                offset: Offset(0, 6),
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
            backgroundColor:
                Colors.transparent, // Gradient handled by parent container
            tooltip: 'Add Loan',
            onPressed: showLoanBottomSheet,
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildLoanList(dynamic loans, {required bool isGuest}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView.builder(
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          final name = isGuest ? loan['name'] : loan['name'] ?? '';
          final amount = isGuest
              ? (loan['amount'] as num).toStringAsFixed(2)
              : (loan['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
          final createdAtDate = isGuest
              ? loan['createdAt'] as DateTime
              : (loan['createdAt'] as Timestamp).toDate();
          final formattedDate = formatDate(createdAtDate);
          final status = isGuest ? loan['status'] : loan['status'] ?? 'Pending';
          final isPaid = status == 'Paid';
          final isOverdue =
              !isPaid && DateTime.now().difference(createdAtDate).inDays > 30;

          if (!isGuest) markOverdue(loan);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) async {
                      await showLoanBottomSheet(
                        existingLoan: isGuest ? null : loan,
                        guestLoan: isGuest ? loan : null,
                      );
                    },
                    icon: Icons.edit,
                    label: 'Edit',
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                  ),
                  SlidableAction(
                    onPressed: (_) async {
                      await showDeleteConfirmationDialog(
                        isGuest ? loan['id'] : loan.id,
                        isGuest: isGuest,
                      );
                    },
                    icon: Icons.delete,
                    label: 'Delete',
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: kPrimaryDark2,
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                    children: [
                      // ==== Left: Icon ====
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryDark2.withOpacity(0.8),
                              kPrimaryDark3.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.tealAccent.shade200,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // ==== Middle: Text Details ====
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Amount: $amount\nDate: $formattedDate",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==== Right: Status Badge ====
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.withOpacity(0.2)
                              : isPaid
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOverdue
                                ? Colors.red.withOpacity(0.4)
                                : isPaid
                                ? Colors.green.withOpacity(0.4)
                                : Colors.orange.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          isOverdue ? 'Overdue' : status,
                          style: GoogleFonts.poppins(
                            color: isOverdue
                                ? Colors.red
                                : isPaid
                                ? Colors.green.shade400
                                : Colors.orange.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
