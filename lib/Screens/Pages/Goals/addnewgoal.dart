import 'package:expanse_tracker_app/Screens/Pages/expanse/Category_breakdown_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Addnewgoal extends StatefulWidget {
  final String? goalId;
  final DocumentSnapshot? existingData;
  final Map<String, dynamic>? guestGoal;
  final Function(Map<String, dynamic>)? onSave; // Callback for guest mode
  final bool isGuest;

  const Addnewgoal({
    this.goalId,
    this.existingData,
    super.key,
    this.guestGoal,
    this.onSave,
    this.isGuest = false,
  });

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
        const SnackBar(
          content: Text("⚠️ Please enter all goal fields!"),
          backgroundColor: kButtonSecondaryBorder, // gold
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
        'createdAt': DateTime.now(),
      };

      // ✅ Guest mode: save locally and call onSave callback
      if (widget.isGuest || FirebaseAuth.instance.currentUser == null) {
        if (widget.onSave != null) widget.onSave!(goalData);
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal saved locally (Guest Mode)!"),
            backgroundColor: kButtonSecondaryBorder,
          ),
        );
        return;
      }

      // ✅ Logged-in user: save to Firestore
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_goals');

      if (widget.goalId != null) {
        // Update existing goal
        await goalRef.doc(widget.goalId).update(goalData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal updated successfully!"),
            backgroundColor: kButtonSecondaryBorder,
          ),
        );
      } else {
        // Add new goal
        await goalRef.add(goalData);

        // Firestore notification
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

        // Local notification
        await _showLocalNotification(
          'New Goal Added',
          'You set a new goal: "$title".',
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal added successfully!"),
            backgroundColor: kButtonSecondaryBorder,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Goal" : "Add New Goal",
          style: const TextStyle(
            color: kAppBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kAppBarColor, // deep blue
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: kAppBarTextColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? "Edit Your Goal" : "Set a New Goal",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kButtonPrimary, // deep blue
                  ),
                ),
                const SizedBox(height: 20),
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
                      backgroundColor: kButtonPrimary, // deep blue
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: kButtonSecondaryBorder, // gold border
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 20.0,
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
              ],
            ),
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
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: kButtonSecondaryBorder), // gold icons
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kButtonSecondaryBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kButtonSecondaryBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kButtonPrimary, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}
