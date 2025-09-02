import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Temporary storage for guest users
List<Map<String, dynamic>> guestExpenses = [];

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddExpenseScreen({super.key, this.existingData, this.docId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  String selectedCategory = "Grocery";
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  final List<String> categories = [
    "Grocery",
    "Health",
    "Food",
    "Transport",
    "Shopping",
    "Home",
    "Bills",
    "Entertainment",
    "Other",
  ];

  final Map<String, IconData> categoryIcons = {
    "Grocery": Icons.shopping_cart,
    "Health": Icons.health_and_safety,
    "Food": Icons.fastfood,
    "Transport": Icons.directions_car,
    "Shopping": Icons.shopping_bag,
    "Home": Icons.home,
    "Bills": Icons.receipt,
    "Entertainment": Icons.movie,
    "Other": Icons.category,
  };

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existingData?['title'] ?? '',
    );
    amountController = TextEditingController(
      text: widget.existingData?['amount']?.toString() ?? '',
    );
    selectedCategory = widget.existingData?['category'] ?? 'Grocery';

    if (widget.existingData != null && widget.existingData!['date'] != null) {
      selectedDate = DateFormat(
        'dd MMM yyyy',
      ).parse(widget.existingData!['date']);
    }
  }

  Future<void> _submitExpense() async {
    if (isLoading) return;

    final title = titleController.text.trim();
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a valid title and amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final newExpense = {
      "title": title,
      "date": DateFormat("dd MMM yyyy").format(selectedDate),
      "amount": amount,
      "vat": "Vat 0.5%",
      "method": "Cash",
      "icon": categoryIcons[selectedCategory]?.codePoint,
      "iconFontFamily": categoryIcons[selectedCategory]?.fontFamily,
      "category": selectedCategory,
      "timestamp": Timestamp.now(),
    };

    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user == null) {
        // Guest Mode → Save locally
        guestExpenses.add(newExpense);
        Navigator.pop(context, newExpense);
      } else {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final expenseCollection = userDoc.collection('users_expenses');

        if (widget.docId != null) {
          await expenseCollection.doc(widget.docId).update(newExpense);
        } else {
          await expenseCollection.add(newExpense);
          await userDoc.collection('users_notifications').add({
            'title': 'New Expense Added',
            'message': 'You added \$${amount.toStringAsFixed(2)} for "$title".',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        Navigator.pop(context, newExpense);
      }
    } catch (e) {
      debugPrint("❌ Error saving expense: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save expense'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null ? "Edit Expense" : "Add Expense",
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 3,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 246, 227, 165)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.deepOrange.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                dialogBackgroundColor: Colors.blueGrey[800],
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.amber,
                                  onPrimary: Colors.black,
                                  surface: Colors.blueGrey,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Title
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration("Expense Title"),
                    ),
                    const SizedBox(height: 18),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration("Amount"),
                    ),
                    const SizedBox(height: 18),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: Colors.amber.shade300,
                      style: const TextStyle(color: Colors.black),
                      iconEnabledColor: Colors.black,
                      onChanged: (value) {
                        if (value != null)
                          setState(() => selectedCategory = value);
                      },
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(categoryIcons[cat], color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                cat,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      decoration: _inputDecoration("Category"),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _submitExpense,
                        child: isLoading
                            ? const SpinKitFadingCircle(
                                color: Colors.white,
                                size: 28,
                              )
                            : Text(
                                widget.existingData != null
                                    ? "SAVE CHANGES"
                                    : "ADD EXPENSE",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
