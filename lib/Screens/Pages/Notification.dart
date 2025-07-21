import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart'; // ✅ NEW

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<String> shownNotificationIds = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification(String title, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'Notification Channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      platformChannelSpecifics,
    );
  }

  void _handleNewNotifications(List<QueryDocumentSnapshot> docs) {
    for (final doc in docs) {
      if (!shownNotificationIds.contains(doc.id)) {
        final title = doc['title'] ?? 'No Title';
        final message = doc['message'] ?? 'No Message';

        shownNotificationIds.add(doc.id);
        _showLocalNotification(title, message);
      }
    }
  }

  Future<void> _selectAndSaveCurrency() async {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'currencyCode': currency.code,
            'currencyFlag': currency.flag,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Currency updated to ${currency.flag} ${currency.code}",
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to update currency: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
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
        actions: [
          IconButton(
            onPressed: _selectAndSaveCurrency,
            icon: const Icon(Icons.attach_money),
            tooltip: 'Select Currency',
            color: Colors.amber,
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text("User not logged in"))
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

                // Show notifications locally
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleNewNotifications(notifications);
                });

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final title = doc['title'] ?? 'No Title';
                    final message = doc['message'] ?? 'No Message';
                    final timestamp = doc['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(timestamp.toDate())
                        : 'Unknown time';

                    return Center(
                      child: Card(
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white, width: 1),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
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
                                  ],
                                ),
                              ),
                            ],
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
