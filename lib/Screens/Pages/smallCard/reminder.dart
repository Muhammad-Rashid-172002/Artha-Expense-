import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/addreminderscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class Reminderscreen extends StatefulWidget {
  const Reminderscreen({super.key});

  @override
  State<Reminderscreen> createState() => _ReminderscreenState();
}

class _ReminderscreenState extends State<Reminderscreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  void _deleteReminder(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('users_reminders')
        .doc(id)
        .delete();
  }

  void _editReminder(DocumentSnapshot reminderDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          isEditing: true,
          reminderId: reminderDoc.id,
          initialTitle: reminderDoc['title'],
          initialDescription: reminderDoc['description'],
          initialDateTime: (reminderDoc['dateTime'] as Timestamp).toDate(),
        ),
      ),
    );
  }

  void _navigateToAddReminder() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reminders",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.blue,
            tooltip: 'Add Reminder',
            onPressed: _isLoading ? null : _navigateToAddReminder,
            child: _isLoading
                ? const SpinKitCircle(color: Colors.white, size: 24)
                : const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('users_reminders')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitCircle(color: Colors.blue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reminders added yet."));
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final date = (reminder['dateTime'] as Timestamp).toDate();

              return Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.blue),
                  title: Text(reminder['title']),
                  subtitle: Text(
                    "${reminder['description']}\n${DateFormat.yMMMd().add_jm().format(date)}",
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReminder(reminder);
                      } else if (value == 'delete') {
                        _deleteReminder(reminder.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
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
