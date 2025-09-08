// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ==== COLOR CONSTANTS ====
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

/// ✅ Guest Loan Store (Temporary Storage)
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

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy – hh:mm a').format(date);
  }

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
        title: const Text("Delete Loan"),
        content: const Text("Are you sure you want to delete this loan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
      backgroundColor: Colors.transparent, // transparent to show gradient
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kButtonPrimary, kButtonSecondaryBorder],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existingLoan == null && guestLoan == null
                          ? "Add Loan"
                          : "Edit Loan",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kHeadingTextColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      dropdownColor: kButtonPrimary,
                      style: const TextStyle(color: Colors.white),
                      items: ["Pending", "Paid"].map((val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Text(
                            val,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setStateSB(() => status = val!),
                      decoration: InputDecoration(
                        labelText: "Status",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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

                          if (name.isEmpty || amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "⚠️ Please enter valid name and amount",
                                ),
                                backgroundColor: Colors.red,
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
                        child: const Text(
                          "Save",
                          style: TextStyle(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loansStream = getUserLoans();

    return Scaffold(
      appBar: AppBar(
        foregroundColor: kAppBarTextColor,
        backgroundColor: kAppBarColor,
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
                ? const Center(child: Text("No loans added yet. (Guest Mode)"))
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
                  return const Center(child: Text("No loans added yet."));
                }

                return buildLoanList(snapshot.data!.docs, isGuest: false);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLoanBottomSheet(),
        backgroundColor: kButtonPrimary,
        child: const Icon(Icons.add, color: Colors.white),
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
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBalanceCardColor.withOpacity(0.4), kButtonPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
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
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.red),
                  title: Text(
                    name,
                    style: const TextStyle(color: kCardTextColor),
                  ),
                  subtitle: Text(
                    "Amount: $amount\nDate: $formattedDate",
                    style: const TextStyle(color: kBodyTextColor),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.shade100
                          : isPaid
                          ? Colors.green.shade100
                          : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue' : status,
                      style: TextStyle(
                        color: isOverdue
                            ? Colors.red
                            : isPaid
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
