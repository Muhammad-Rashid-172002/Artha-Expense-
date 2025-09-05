import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class AddReminderScreen extends StatefulWidget {
  final bool isEditing;
  final String? reminderId;
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDateTime;

  const AddReminderScreen({
    super.key,
    this.isEditing = false,
    this.reminderId,
    this.initialTitle,
    this.initialDescription,
    this.initialDateTime,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedDateTime = widget.initialDateTime;

    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  void _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.green,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _pickDateTime() async {
    final currentDate = DateTime.now();

    // Date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? currentDate.add(const Duration(days: 1)),
      firstDate: currentDate,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.greenAccent, // Selected date
            onPrimary: Colors.white, // Text on selected date
            surface: Color(0xFFFFF3E0), // Light amber background for date cells
            onSurface: Colors.lightGreen, // Text on date cells
          ),
          dialogBackgroundColor: const Color(
            0xFFFFF8E1,
          ), // Very light amber background
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      // Time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFFFFF8E1), // Very light amber
              hourMinuteTextColor: Colors.deepOrange,
              hourMinuteColor: Colors.orangeAccent,
              dialHandColor: Colors.deepOrange,
              dialBackgroundColor: Colors.orange,
              entryModeIconColor: Colors.deepOrange,
              dayPeriodTextColor: Colors.black,
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              surface: Colors.orangeAccent,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      _showSnackbar("Please fill all fields");
      return;
    }

    if (_selectedDateTime == null) {
      _showSnackbar("Please pick a date & time");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final reminderData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dateTime': _selectedDateTime,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final remindersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('users_reminders');

      if (widget.isEditing && widget.reminderId != null) {
        await remindersRef.doc(widget.reminderId).update(reminderData);
        _showSnackbar("Reminder updated successfully");
      } else {
        await remindersRef.add(reminderData);
        _showLocalNotification(
          "Reminder Added!",
          "You added a reminder: ${_titleController.text.trim()}",
        );
        _showSnackbar("Reminder added successfully");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackbar("Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDateTime != null
        ? DateFormat.yMMMMd().add_jm().format(_selectedDateTime!)
        : "Pick Date & Time";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Edit Reminder" : "Add Reminder",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Title",
                      hintText: "Enter your reminder title",
                      hintStyle: const TextStyle(color: Colors.green),
                      labelStyle: const TextStyle(color: Colors.green),
                      prefixIcon: const Icon(Icons.title, color: Colors.green),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Description",
                      hintText: "Enter details about your reminder",
                      hintStyle: const TextStyle(color: Colors.green),
                      labelStyle: const TextStyle(color: Colors.green),
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.green,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter a description"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.amber[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.green),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.green,
                    ),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.green,
                            size: 40.0,
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            widget.isEditing
                                ? "Update Reminder"
                                : "Save Reminder",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saveReminder,
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
