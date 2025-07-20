import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Addnewgoal extends StatefulWidget {
  final String? goalId;
  final DocumentSnapshot? existingData;

  const Addnewgoal({this.goalId, this.existingData});

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
    final title = titleController.text.trim();
    final currentText = currentController.text.trim();
    final targetText = targetController.text.trim();

    if (title.isEmpty || currentText.isEmpty || targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please enter all goal fields!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not authenticated.");

      final current = double.tryParse(currentText) ?? 0;
      final target = double.tryParse(targetText) ?? 0;

      final goalData = {
        'title': title,
        'current': current,
        'target': target,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_goals');

      if (widget.goalId != null) {
        // Update goal (edit)
        await goalRef.doc(widget.goalId).update(goalData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new goal
        await goalRef.add(goalData);

        // Add Firestore notification with `shown: true`
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('users_notifications')
            .add({
              'title': 'New Goal Added',
              'message': 'You set a new goal: "$title".',
              'timestamp': FieldValue.serverTimestamp(),
              'shown': false, // ✅ Prevent duplicate notification
            });

        // Show local notification once
        await _showLocalNotification(
          'New Goal Added',
          'You set a new goal: "$title".',
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Goal added successfully!"),
            backgroundColor: Colors.green,
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
      backgroundColor: const Color.fromARGB(255, 138, 205, 238),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Goal" : "Add New Goal"),
        backgroundColor: const Color.fromARGB(255, 3, 130, 234),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Goal Title",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Current Savings",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.savings),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Amount",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.track_changes),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isEditing ? "Update Goal" : "Save Goal",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
      ),
    );
  }
}
