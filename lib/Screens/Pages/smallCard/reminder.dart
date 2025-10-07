import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/addreminderscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

/// Guest reminder storage
class GuestReminderStore {
  static final List<Map<String, dynamic>> _reminders = [];

  static List<Map<String, dynamic>> get reminders =>
      List<Map<String, dynamic>>.from(_reminders)
        ..sort((a, b) => (a['dateTime'] as DateTime)
            .compareTo(b['dateTime'] as DateTime));

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

// COLORS
const kPrimaryGradient1 = Color(0xFF0F2027);
const kPrimaryGradient2 = Color(0xFF203A43);
const kPrimaryGradient3 = Color(0xFF2C5364);
const kAccentColor = Color(0xFF00BCD4); // Bright cyan
const kBodyTextColor = Colors.white70;

class Reminderscreen extends StatefulWidget {
  const Reminderscreen({super.key});

  @override
  State<Reminderscreen> createState() => _ReminderscreenState();
}

class _ReminderscreenState extends State<Reminderscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _deleteReminder(String id) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );
  }

  Future<void> _confirmDeleteReminder(String reminderId,
      {bool isGuest = false}) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Reminder",
          style: GoogleFonts.poppins(
              color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this reminder?",
          style: GoogleFonts.poppins(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Delete",
                style: GoogleFonts.poppins(color: Colors.white)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reminder deleted",
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = currentUser == null;

    return Scaffold(
      backgroundColor: kPrimaryGradient1,
      appBar: AppBar(
        title: Text(
          "Reminders",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      //  _isLoading ? null : (isGuest ? () => {} : _navigateToAddReminder),

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
            tooltip: 'Add Income',
            onPressed:(isGuest ? () => {} : _navigateToAddReminder),
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      body: isGuest ? _buildGuestList() : _buildFirestoreList(currentUser!.uid),
    );
  }

  Widget _buildGuestList() {
    final reminders = GuestReminderStore.reminders;
    if (reminders.isEmpty) {
      return Center(
        child: Text(
          "No reminders yet (Guest).",
          style: GoogleFonts.poppins(color: kBodyTextColor, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final date = reminder['dateTime'] as DateTime;

        return _reminderCard(
          title: reminder['title'],
          description: reminder['description'],
          date: date,
          onEdit: () => {},
          onDelete: () =>
              _confirmDeleteReminder(reminder['id'] as String, isGuest: true),
        );
      },
    );
  }

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
          return const Center(child: SpinKitCircle(color: Colors.white));

        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No reminders yet.",
              style: GoogleFonts.poppins(color: kBodyTextColor, fontSize: 16),
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

            return _reminderCard(
              title: reminder['title'],
              description: reminder['description'],
              date: date,
              onEdit: () => _editReminder(reminder),
              onDelete: () => _confirmDeleteReminder(reminder.id),
            );
          },
        );
      },
    );
  }

  Widget _reminderCard({
    required String title,
    required String description,
    required DateTime date,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGradient2, kPrimaryGradient3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.alarm, color: Colors.amberAccent, size: 28),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text("$description\n${DateFormat.yMMMd().add_jm().format(date)}",
            style: GoogleFonts.poppins(color: kBodyTextColor, fontSize: 14)),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          color: kAccentColor,
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
