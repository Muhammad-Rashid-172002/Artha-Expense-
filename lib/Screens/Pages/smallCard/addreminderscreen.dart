import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedDateTime = widget.initialDateTime;
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              timePickerTheme: const TimePickerThemeData(
                backgroundColor: Colors.black,
                hourMinuteTextColor: Colors.amber,
                hourMinuteColor: Colors.white10,
                dialHandColor: Colors.amber,
                dialBackgroundColor: Colors.grey,
                entryModeIconColor: Colors.amber,
                dayPeriodTextColor: Colors.white,
              ),
              colorScheme: const ColorScheme.dark(
                primary: Colors.amber,
                onPrimary: Colors.black,
                surface: Colors.grey,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
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
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDateTime != null
        ? DateFormat.yMMMMd().add_jm().format(_selectedDateTime!)
        : "Pick Date & Time";

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Edit Reminder" : "Add Reminder",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Title",
                      hintText: "Enter your reminder title",
                      hintStyle: const TextStyle(color: Colors.white38),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.title, color: Colors.amber),

                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.amber,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
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
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                      hintText: "Enter details about your reminder",
                      hintStyle: const TextStyle(color: Colors.white38),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.amber,
                      ),
                      filled: true,
                      fillColor: Colors.grey[850],
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.amber,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
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
                    tileColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.amber,
                    ),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.amber,
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
                            backgroundColor: Colors.amber,
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
