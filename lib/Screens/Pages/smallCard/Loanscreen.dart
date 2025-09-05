// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Temporary storage for guest reminders (in-memory)
class GuestReminderStore {
  static final List<Map<String, dynamic>> _gustLoan = [];

  static List<Map<String, dynamic>> get reminders =>
      List<Map<String, dynamic>>.from(_gustLoan)..sort(
        (a, b) =>
            (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime),
      );

  static void addReminder({
    required String title,
    required String description,
    required DateTime dateTime,
  }) {
    _gustLoan.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'dateTime': dateTime,
    });
  }

  static void editReminder({
    required String id,
    required String title,
    required String description,
    required DateTime dateTime,
  }) {
    final idx = _gustLoan.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _gustLoan[idx] = {
        'id': id,
        'title': title,
        'description': description,
        'dateTime': dateTime,
      };
    }
  }

  static void deleteReminder(String id) {
    _gustLoan.removeWhere((r) => r['id'] == id);
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

  // ✅ Local storage for guest loans
  List<Map<String, dynamic>> guestLoans = [];

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
        guestLoans.removeWhere((loan) => loan['id'] == loanId);
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
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Delete Loan",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Are you sure you want to delete this loan?",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.amber.shade50),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldDelete == true) {
      if (isGuest) {
        guestLoans.removeWhere((loan) => loan['id'] == loanId);
        setState(() {});
      } else {
        final loanRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('users_loans');
        await loanRef.doc(loanId).delete();
      }
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
      backgroundColor: Colors.transparent, // use transparent for gradient
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.greenAccent.shade100, // light top
                Colors.green.shade700,
              ], // middle],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existingLoan == null && guestLoan == null
                            ? "Add Loan"
                            : "Edit Loan",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: status,
                        dropdownColor: Colors.greenAccent.shade200,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                        ),
                        items: ['Pending', 'Paid'].map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => status = val!),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.amber.shade100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final amount = double.tryParse(
                                amountController.text.trim(),
                              );

                              if (name.isEmpty ||
                                  amount == null ||
                                  amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please enter valid name and amount.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (user == null) {
                                // Guest mode
                                setState(() {
                                  if (guestLoan == null) {
                                    guestLoans.add({
                                      'id': DateTime.now().toString(),
                                      'name': name,
                                      'amount': amount,
                                      'status': status,
                                      'createdAt': DateTime.now(),
                                    });
                                  } else {
                                    guestLoan['name'] = name;
                                    guestLoan['amount'] = amount;
                                    guestLoan['status'] = status;
                                  }
                                });
                              } else {
                                // Logged in mode
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text(
                              "Save",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
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
        backgroundColor: Colors.green,
        title: Text(
          'Loan List',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white, //  BlueGrey
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,

        foregroundColor: Colors.white,
      ),
      body: user == null
          // ✅ Guest loans list
          ? guestLoans.isEmpty
                ? const Center(
                    child: Text(
                      "No loans added yet. (Guest Mode)",
                      style: TextStyle(color: Colors.black87),
                    ),
                  )
                : buildLoanList(guestLoans, isGuest: true)
          // ✅ Firestore loans list
          : StreamBuilder<QuerySnapshot>(
              stream: loansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitCircle(color: Colors.black),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No loans added yet.",
                      style: TextStyle(color: Colors.black87),
                    ),
                  );
                }

                return buildLoanList(snapshot.data!.docs, isGuest: false);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLoanBottomSheet(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget buildLoanList(dynamic loans, {required bool isGuest}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "Your Loans",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
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
                final status = isGuest
                    ? loan['status']
                    : loan['status'] ?? 'Pending';
                final isPaid = status == 'Paid';
                final isOverdue =
                    !isPaid &&
                    DateTime.now().difference(createdAtDate).inDays > 30;

                if (!isGuest) markOverdue(loan);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.greenAccent.shade100, // light top
                        Colors.green.shade700, // middle
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade100.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: Text(
                          "Amount: $amount\nDate: $formattedDate",
                          style: const TextStyle(color: Colors.black54),
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
          ),
        ],
      ),
    );
  }
}
