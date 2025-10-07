import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/smallCard/saving.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// ==== COLORS ====
const Color kAppBarColor = Color(0xFF1F2A38); // Dark Blue-Gray
const Color kAppBarTextColor = Colors.white; // White text
const Color kButtonPrimary = Color(0xFF00BFA5); // Teal Accent
const Color kButtonPrimaryText = Colors.white; // White text
const Color kCardColor = Color(0xFF2C3E50); // Dark card background
const Color kCardTextColor = Colors.white; // White text for dark card
const Color kFadedTextColor = Colors.grey; // Faded/secondary

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
          color: kButtonPrimary,
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

    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? currentDate.add(const Duration(days: 1)),
      firstDate: currentDate,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: kButtonPrimary,
            onPrimary: kButtonPrimaryText,
            surface: kCardColor,
            onSurface: kCardTextColor,
          ),
          dialogBackgroundColor: kCardColor,
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: kCardColor,
              hourMinuteTextColor: kButtonPrimaryText,
              hourMinuteColor: kButtonPrimary,
              dialHandColor: kButtonPrimary,
              dialBackgroundColor: kCardColor,
              entryModeIconColor: kButtonPrimary,
              dayPeriodTextColor: kCardTextColor,
            ),
            colorScheme: ColorScheme.light(
              primary: kButtonPrimary,
              onPrimary: kButtonPrimaryText,
              surface: kCardColor,
              onSurface: kCardTextColor,
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
    if (!_formKey.currentState!.validate()) {
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
      if (currentUser == null) {
        _showSnackbar("User not logged in!");
        return;
      }

      final reminderData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dateTime': _selectedDateTime,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final remindersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
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

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackbar("Something went wrong. Try again.\n$e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kButtonPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDateTime != null
        ? DateFormat.yMMMMd().add_jm().format(_selectedDateTime!)
        : "Pick Date & Time";

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.isEditing ? "Edit Reminder" : "Add Reminder",
            style: GoogleFonts.poppins(
              color: kAppBarTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    Card(
                      elevation: 4,
                      shadowColor: kButtonPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(
                          color: Colors.black87, // Dark text for visibility
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: "Title",
                          hintText: "Enter your reminder title",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black45, // lighter hint text
                            fontWeight: FontWeight.w400,
                          ),
                          labelStyle: GoogleFonts.poppins(
                            color: kButtonPrimary, // Matches app theme
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: Icon(Icons.title, color: kButtonPrimary),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                            0.9,
                          ), // lighter fill for contrast
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter a title"
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Card(
                      elevation: 4,
                      shadowColor: kButtonPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(
                          color: Colors.black87, // Dark text for visibility
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: "Description",
                          hintText: "Enter details about your reminder",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black45, // lighter hint text
                            fontWeight: FontWeight.w400,
                          ),
                          labelStyle: GoogleFonts.poppins(
                            color: kButtonPrimary, // Matches app theme
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: kButtonPrimary,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                            0.9,
                          ), // lighter fill for contrast
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter a description"
                            : null,
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Date & Time
                    ListTile(
                      tileColor: kCardColor.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        formattedDate,
                        style: GoogleFonts.poppins(color: kButtonPrimaryText),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: kButtonPrimary,
                      ),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    GestureDetector(
                      onTap: _isLoading ? null : _saveReminder,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [kButtonPrimary, Color(0xFF00E5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: kButtonPrimary,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.isEditing
                                ? "Update Reminder"
                                : "Save Reminder",
                            style: GoogleFonts.poppins(
                              color: kButtonPrimaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: SpinKitFadingCircle(color: kButtonPrimary, size: 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
