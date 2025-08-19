import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

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

  Future<void> _scheduleNotification(
    DateTime scheduledTime,
    String title,
    String message,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        selectedDate.isBefore(DateTime.now())) {
      _showSnackbar("Please fill all fields correctly");
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final remindersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reminders');

    final reminderData = {
      'title': title,
      'description': description,
      'time': selectedDate,
      'createdAt': Timestamp.now(),
    };

    await remindersRef.add(reminderData);

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_notifications');

    await notificationsRef.add({
      'title': 'Reminder: $title',
      'message': description,
      'timestamp': Timestamp.fromDate(selectedDate),
      'isShown': false,
    });

    await _scheduleNotification(selectedDate, 'Reminder: $title', description);

    _showSnackbar("Reminder saved and scheduled!");
    Navigator.pop(context);
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

  Future<void> _handleNewNotifications(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isShown = data['isShown'] ?? false;

      if (!isShown) {
        final title = data['title'] ?? 'No Title';
        final message = data['message'] ?? 'No Message';

        await _showLocalNotification(title, message);
        await doc.reference.update({'isShown': true});
      }
    }
  }

  Future<void> _confirmDelete(DocumentReference docRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        title: const Text(
          "Delete Notification",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this notification?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await docRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification deleted"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: userId == null
          ? const Center(
              child: Text(
                "User not logged in",
                style: TextStyle(color: Colors.white),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Notifications yet.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleNewNotifications(notifications);
                });

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'No Title';
                    final message = data['message'] ?? 'No Message';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(timestamp.toDate())
                        : 'Unknown time';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _confirmDelete(doc.reference);
                        return false;
                      },
                      child: Center(
                        child: Card(
                          color: Colors.grey[850],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 80,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.notifications,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
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
                );
              },
            ),
    );
  }
}
