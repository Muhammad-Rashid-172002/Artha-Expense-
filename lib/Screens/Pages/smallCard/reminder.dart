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

  Future<void> _deleteReminder(String id) async {
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

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );
  }

  Future<void> _confirmDeleteReminder(String reminderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Delete Reminder",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this reminder?",
          style: TextStyle(color: Colors.white70),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteReminder(reminderId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reminder deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
          "Reminders",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        tooltip: 'Add Reminder',
        onPressed: _isLoading ? null : _navigateToAddReminder,
        child: _isLoading
            ? const SpinKitCircle(color: Colors.white, size: 24)
            : const Icon(Icons.add, color: Colors.blueGrey),
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
            return const Center(child: SpinKitCircle(color: Colors.amber));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reminders added yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final date = (reminder['dateTime'] as Timestamp).toDate();

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white24),
                ),
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.amber),
                  title: Text(
                    reminder['title'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${reminder['description']}\n${DateFormat.yMMMd().add_jm().format(date)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    color: Colors.grey[900],
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReminder(reminder);
                      } else if (value == 'delete') {
                        _confirmDeleteReminder(reminder.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
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
