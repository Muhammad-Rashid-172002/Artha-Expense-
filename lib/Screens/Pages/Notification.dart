import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ==== Colors (matching your dark theme) ====
const Color kPrimaryDark1 = Color(0xFF1C1F26);
const Color kPrimaryDark2 = Color(0xFF2A2F3A);
const Color kPrimaryDark3 = Color(0xFF383C4C);
const Color kAccent = Color(0xFF00E676); // For icons/buttons text
const Color kWhite = Colors.white;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(minutes: 1));

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    checkRemainingIncome();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      notificationDetails,
    );
  }

  Future<void> checkRemainingIncome() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final data = userDoc.data();
    if (data == null) return;

    final income = (data['income'] as num?)?.toDouble() ?? 0.0;
    final expenses = (data['expenses'] as num?)?.toDouble() ?? 0.0;
    final remaining = income - expenses;

    if (remaining <= 100) {
      await _showLocalNotification(
        "Low Remaining Income",
        "Your remaining income is only \$${remaining.toStringAsFixed(2)}",
      );
    }
  }

  Future<void> _confirmDelete(DocumentReference docRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPrimaryDark2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: kAccent, width: 1.5),
        ),
        title: Text(
          "Delete Notification",
          style: GoogleFonts.poppins(
            color: kWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this notification?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: kAccent, fontWeight: FontWeight.w500)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Delete",
                style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await docRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: Colors.redAccent.shade400,
            content: Text(
              "Notification deleted",
              style: GoogleFonts.poppins(color: kWhite, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: kAccent,
        content: Text(
          message,
          style: GoogleFonts.poppins(color: kWhite, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        backgroundColor: kPrimaryDark2,
        automaticallyImplyLeading: false,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kWhite,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: userId == null
          ? Center(
              child: Text(
                "User not logged in",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('users_notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Notifications yet.',
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'No Title';
                    final message = data['message'] ?? 'No Message';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                        : 'Unknown time';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red.shade400,
                        child: const Icon(Icons.delete, color: kWhite),
                      ),
                      confirmDismiss: (_) async {
                        await _confirmDelete(doc.reference);
                        return false;
                      },
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryDark2, kPrimaryDark3],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.notifications, color: kAccent, size: 28),
                            title: Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: kWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
