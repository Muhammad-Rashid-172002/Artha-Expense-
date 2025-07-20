import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      setState(() => _isLoading = true);
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
      } else {
        await remindersRef.add(reminderData);
      }

      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Edit Reminder" : "Add Reminder",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter a description" : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      _selectedDateTime == null
                          ? "Pick Date & Time"
                          : "Reminder at: ${_selectedDateTime!.toLocal()}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.blue,
                            size: 40.0,
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            widget.isEditing
                                ? "Update Reminder"
                                : "Save Reminder",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
