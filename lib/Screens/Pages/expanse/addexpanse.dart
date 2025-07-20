import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId; // 🔁 Add docId to identify the document being edited

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

  // ✅ Updated: Clean, consistent category list
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

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an expense title and amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    final newExpense = {
      "title": title,
      "date": DateFormat("dd MMM yyyy").format(selectedDate),
      "amount": double.tryParse(amountText) ?? 0,
      "vat": "Vat 0.5%",
      "method": "Cash",
      "icon": categoryIcons[selectedCategory]?.codePoint,
      "iconFontFamily": categoryIcons[selectedCategory]?.fontFamily,
      "category": selectedCategory,
      "timestamp": Timestamp.now(),
    };

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users_expenses');

      if (widget.docId != null) {
        // 📝 Update existing document
        await collectionRef.doc(widget.docId).update(newExpense);
      } else {
        // ➕ Add new expense
        await collectionRef.add(newExpense);
        // ✅ SEND NOTIFICATION TO Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('users_notifications')
            .add({
              'title': 'New Expense Added',
              'message': 'You added ${amountText} for "$title".',
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      Navigator.pop(context, newExpense);
    } catch (e) {
      print("Error saving expense: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null ? "Edit Expense" : "Add Expense",
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Expense Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ REPLACED ChoiceChip section with DropdownButtonFormField
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedCategory = value);
                }
              },
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),

            // ✅ End of update
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading ? null : _submitExpense,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingData != null
                            ? "SAVE CHANGES"
                            : "ADD EXPENSE",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
