import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/addreminderscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

/// Temporary storage for guest reminders (in-memory)
class GuestReminderStore {
  static final List<Map<String, dynamic>> _reminders = [];

  static List<Map<String, dynamic>> get reminders =>
      List<Map<String, dynamic>>.from(_reminders)..sort(
        (a, b) =>
            (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime),
      );

  static void addReminder({
    required String title,
    required String description,
    required DateTime dateTime,
  }) {
    _reminders.add({
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
    final idx = _reminders.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _reminders[idx] = {
        'id': id,
        'title': title,
        'description': description,
        'dateTime': dateTime,
      };
    }
  }

  static void deleteReminder(String id) {
    _reminders.removeWhere((r) => r['id'] == id);
  }
}

class Reminderscreen extends StatefulWidget {
  const Reminderscreen({super.key});

  @override
  State<Reminderscreen> createState() => _ReminderscreenState();
}

class _ReminderscreenState extends State<Reminderscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // ---------- Firestore helpers ----------
  Future<void> _deleteReminder(String id) async {
    final uid = currentUser?.uid;
    if (uid == null) return; // Guest: ignore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
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
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Logged-in: go to normal AddReminder screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );
  }

  // ---------- Guest mode: add/edit dialog ----------
  Future<void> _openGuestReminderDialog({Map<String, dynamic>? initial}) async {
    final titleCtrl = TextEditingController(text: initial?['title'] ?? '');
    final descCtrl = TextEditingController(text: initial?['description'] ?? '');
    DateTime selectedDateTime =
        (initial?['dateTime'] as DateTime?) ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    initial == null ? 'Add Reminder (Guest)' : 'Edit Reminder',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            DateFormat.yMMMd().add_jm().format(
                              selectedDateTime,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (_, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.amber,
                                  surface: Colors.black,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ),
                            builder: (_, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.amber,
                                  surface: Colors.black,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (time == null) return;
                          final dt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          setModal(() => selectedDateTime = dt);
                        },
                        icon: const Icon(Icons.schedule, color: Colors.black),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        label: const Text('Pick Date & Time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title cannot be empty'),
                            ),
                          );
                          return;
                        }
                        if (initial == null) {
                          GuestReminderStore.addReminder(
                            title: title,
                            description: desc,
                            dateTime: selectedDateTime,
                          );
                        } else {
                          GuestReminderStore.editReminder(
                            id: initial['id'] as String,
                            title: title,
                            description: desc,
                            dateTime: selectedDateTime,
                          );
                        }
                        Navigator.pop(context);
                        setState(() {}); // refresh list
                      },
                      icon: const Icon(Icons.save, color: Colors.black),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(initial == null ? 'Save Reminder' : 'Update'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteReminder(
    String reminderId, {
    bool isGuest = false,
  }) async {
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
      if (isGuest) {
        GuestReminderStore.deleteReminder(reminderId);
        if (!mounted) return;
        setState(() {});
      } else {
        await _deleteReminder(reminderId);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reminder deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = currentUser == null;

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
        onPressed: _isLoading
            ? null
            : (isGuest
                  ? () => _openGuestReminderDialog()
                  : _navigateToAddReminder),
        child: _isLoading
            ? const SpinKitCircle(color: Colors.white, size: 24)
            : const Icon(Icons.add, color: Colors.blueGrey),
      ),
      body: isGuest ? _buildGuestList() : _buildFirestoreList(currentUser!.uid),
    );
  }

  // ---------- Guest list ----------
  Widget _buildGuestList() {
    final reminders = GuestReminderStore.reminders;
    if (reminders.isEmpty) {
      return const Center(
        child: Text(
          "No reminders added yet (Guest).",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final date = reminder['dateTime'] as DateTime;

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
              reminder['title'] as String,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "${reminder['description'] ?? ''}\n${DateFormat.yMMMd().add_jm().format(date)}",
              style: const TextStyle(color: Colors.white70),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              color: Colors.grey[900],
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _openGuestReminderDialog(initial: reminder);
                } else if (value == 'delete') {
                  _confirmDeleteReminder(
                    reminder['id'] as String,
                    isGuest: true,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
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
  }

  // ---------- Firestore list ----------
  Widget _buildFirestoreList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    PopupMenuItem(
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
    );
  }
}
