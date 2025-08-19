// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  Stream<QuerySnapshot> getUserLoans() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('users_loans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy – hh:mm a').format(date);
  }

  Future<void> markOverdue(DocumentSnapshot doc) async {
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

  Future<void> deleteLoan(String loanId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('users_loans')
        .doc(loanId)
        .delete();
  }

  Future<void> showDeleteConfirmationDialog(String loanId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Delete Loan", style: TextStyle(color: Colors.amber)),
        content: const Text(
          "Are you sure you want to delete this loan?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await deleteLoan(loanId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑️ Loan deleted."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> showLoanDialog({DocumentSnapshot? existingLoan}) async {
    final nameController = TextEditingController(
      text: existingLoan != null ? existingLoan['name'] : '',
    );
    final amountController = TextEditingController(
      text: existingLoan != null
          ? (existingLoan['amount'] as num).toString()
          : '',
    );
    String status = existingLoan != null ? existingLoan['status'] : 'Pending';

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              existingLoan == null ? "Add Loan" : "Edit Loan",
              style: const TextStyle(color: Colors.amber),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());

                  if (name.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter valid name and amount."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ New loan added!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    await loanRef.doc(existingLoan.id).update({
                      'name': name,
                      'amount': amount,
                      'status': status,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✏️ Loan updated successfully!"),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Loan List"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: getUserLoans(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitCircle(color: Colors.white));
          }

          final loans = snapshot.data!.docs;

          if (loans.isEmpty) {
            return const Center(
              child: Text(
                "No loans added yet.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

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
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      final name = loan['name'] ?? '';
                      final amount =
                          (loan['amount'] as num?)?.toStringAsFixed(2) ??
                          '0.00';
                      final timestamp = loan['createdAt'] as Timestamp;
                      final createdAtDate = timestamp.toDate();
                      final formattedDate = formatDate(timestamp);
                      final status = loan.data().toString().contains('status')
                          ? loan['status']
                          : 'Pending';
                      final isPaid = status == 'Paid';
                      final isOverdue =
                          !isPaid &&
                          DateTime.now().difference(createdAtDate).inDays > 30;

                      markOverdue(loan);

                      return Card(
                        elevation: 3,
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Slidable(
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) async {
                                  await showLoanDialog(existingLoan: loan);
                                },
                                icon: Icons.edit,
                                label: 'Edit',
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              SlidableAction(
                                onPressed: (_) async {
                                  await showDeleteConfirmationDialog(loan.id);
                                },
                                icon: Icons.delete,
                                label: 'Delete',
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.amber,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Amount: $amount\nDate: $formattedDate",
                              style: const TextStyle(color: Colors.white70),
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
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOverdue ? 'Overdue' : status,
                                style: TextStyle(
                                  color: isOverdue
                                      ? Colors.red
                                      : isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLoanDialog(),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }
}
