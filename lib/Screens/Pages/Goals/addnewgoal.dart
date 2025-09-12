import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      // Editing Firestore goal
      titleController.text = widget.existingData!['title'];
      currentController.text = widget.existingData!['current'].toString();
      targetController.text = widget.existingData!['target'].toString();
    } else if (widget.guestGoal != null) {
      // Editing Guest goal
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
        const SnackBar(
          content: Text("⚠️ Please enter all goal fields!"),
          backgroundColor: kButtonSecondaryBorder,
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

      // ✅ Guest Mode
      if (widget.isGuest || FirebaseAuth.instance.currentUser == null) {
        if (widget.onSave != null) {
          widget.onSave!(goalData);
        }
        Navigator.pop(context, true);
        return;
      }

      // ✅ Firestore Mode
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_goals');

      if (widget.goalId != null) {
        // 🔄 Update existing goal
        await goalRef.doc(widget.goalId).update(goalData);
        await _showLocalNotification(
          "Goal Updated",
          "Your goal '$title' was updated.",
        );
      } else {
        // ➕ Add new goal
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
          content: Text('Error saving goal: $e'),
          backgroundColor: Colors.red,
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
        title: const Text("Delete Goal"),
        content: const Text("Are you sure you want to delete this goal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      if (widget.isGuest && widget.guestGoal != null) {
        // Delete guest goal
        if (widget.onSave != null) {
          widget.onSave!({'delete': true, 'id': widget.guestGoal!['id']});
        }
      } else if (widget.goalId != null &&
          FirebaseAuth.instance.currentUser != null) {
        // Delete Firestore goal
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
          content: Text("Error deleting goal: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalId != null || widget.guestGoal != null;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? "Edit Goal" : "Add New Goal",
          style: const TextStyle(
            color: kAppBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kAppBarColor,
        centerTitle: true,
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
              _buildTextField(
                controller: titleController,
                label: "Goal Title",
                icon: Icons.flag,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: currentController,
                label: "Current Savings",
                icon: Icons.savings,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: targetController,
                label: "Target Amount",
                icon: Icons.track_changes,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: kButtonSecondaryBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kButtonSecondaryBorder),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
