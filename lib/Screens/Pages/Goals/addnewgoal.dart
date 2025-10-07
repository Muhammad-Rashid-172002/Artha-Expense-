import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/montlybudget.dart'
    hide
        kButtonPrimaryText,
        kButtonPrimary,
        kAppBarColor,
        kAppBarTextColor,
        kButtonSecondaryBorder;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

/// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF0F2027);
const Color kPrimaryDark2 = Color(0xFF203A43);
const Color kPrimaryDark3 = Color(0xFF2C5364);
const Color kCardDark = Color(0xFF1C1C1E);
const Color kAccentColor = Color(0xFFFFA500);
const Color kWhite = Colors.white;
const Color kTextHeading = Colors.white;
const Color kTextSubtitle = Colors.white70;
const Color kTextBody = Colors.white;
const Color kTextSecondary = Colors.white54;

/// Button colors
const Color kButtonPrimary = Color(0xFFFFA500);
const Color kButtonPrimaryText = Colors.white;
const Color kButtonSecondaryBorder = Colors.white54;
const Color kAppBarColor = kPrimaryDark3;
const Color kAppBarTextColor = kWhite;

class Addnewgoal extends StatefulWidget {
  final String? goalId; // Firestore doc id
  final DocumentSnapshot? existingData; // Firestore doc snapshot
  final Map<String, dynamic>? guestGoal; // Guest mode local goal
  final Function(Map<String, dynamic>)? onSave; // Callback for guest mode
  final bool isGuest;

  const Addnewgoal({
    Key? key,
    this.goalId,
    this.existingData,
    this.guestGoal,
    this.onSave,
    this.isGuest = false,
  }) : super(key: key);

  @override
  State<Addnewgoal> createState() => _AddnewgoalState();
}

class _AddnewgoalState extends State<Addnewgoal> {
  final titleController = TextEditingController();
  final currentController = TextEditingController();
  final targetController = TextEditingController();

  bool isLoading = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Currency symbol
  String currencySymbol = "\$";

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      titleController.text = widget.existingData!['title'];
      currentController.text = widget.existingData!['current'].toString();
      targetController.text = widget.existingData!['target'].toString();
    } else if (widget.guestGoal != null) {
      titleController.text = widget.guestGoal!['title'];
      currentController.text = widget.guestGoal!['current'].toString();
      targetController.text = widget.guestGoal!['target'].toString();
    }

    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showLocalNotification(String title, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Goal Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      platformDetails,
    );
  }

  Future<void> saveGoal() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final title = titleController.text.trim();
    final currentText = currentController.text.trim();
    final targetText = targetController.text.trim();

    if (title.isEmpty || currentText.isEmpty || targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    " Please enter all goal fields!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() => isLoading = false);
      return;
    }

    try {
      final current = double.tryParse(currentText) ?? 0;
      final target = double.tryParse(targetText) ?? 0;

      final goalData = {
        'title': title,
        'current': current,
        'target': target,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Guest Mode
      if (widget.isGuest || FirebaseAuth.instance.currentUser == null) {
        if (widget.onSave != null) widget.onSave!(goalData);
        Navigator.pop(context, true);
        return;
      }

      // Firestore Mode
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_goals');

      if (widget.goalId != null) {
        await goalRef.doc(widget.goalId).update(goalData);
        await _showLocalNotification(
          "Goal Updated",
          "Your goal '$title' was updated.",
        );
      } else {
        await goalRef.add({
          ...goalData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('users_notifications')
            .add({
              'title': 'New Goal Added',
              'message': 'You set a new goal: "$title".',
              'timestamp': FieldValue.serverTimestamp(),
              'shown': false,
            });

        await _showLocalNotification(
          "New Goal Added",
          "You set a new goal: $title",
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFEF5350)], // Red gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error saving goal: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final isEditing = widget.goalId != null || widget.guestGoal != null;

    if (!isEditing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPrimaryDark2,
        title: Text("Delete Goal", style: TextStyle(color: kWhite)),
        content: Text(
          "Are you sure you want to delete this goal?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: kWhite)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      if (widget.isGuest && widget.guestGoal != null) {
        if (widget.onSave != null) {
          widget.onSave!({'delete': true, 'id': widget.guestGoal!['id']});
        }
      } else if (widget.goalId != null &&
          FirebaseAuth.instance.currentUser != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('users_goals')
            .doc(widget.goalId)
            .delete();
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFEF5350)], // Red gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Error deleting goal: $e",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalId != null || widget.guestGoal != null;

    return Scaffold(
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? "Edit Goal" : "Add New Goal",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor:Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _confirmDelete,
            ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildGlassTextField(
                controller: titleController,
                label: "Goal Title",
                icon: Icons.flag,
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: currentController,
                label: "Current Savings",
                icon: Icons.savings,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: targetController,
                label: "Target Amount",
                icon: Icons.track_changes,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonPrimary.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: kButtonSecondaryBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 20,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing ? Icons.update : Icons.save,
                                  color: kButtonPrimaryText,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isEditing ? "Update Goal" : "Save Goal",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kButtonPrimaryText,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
