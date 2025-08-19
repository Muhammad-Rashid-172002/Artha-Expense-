import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          content: Text('Please enter a valid title and amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
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

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final expenseCollection = userDoc.collection('users_expenses');

      // 🔍 Check and update category budget (only on new expense)
      if (widget.docId == null) {
        final budgetQuery = await userDoc
            .collection('category_budgets')
            .where('category', isEqualTo: selectedCategory)
            .limit(1)
            .get();

        if (budgetQuery.docs.isNotEmpty) {
          final doc = budgetQuery.docs.first;
          final currentUsed = doc['used'] ?? 0.0;
          final budget = doc['budget'] ?? 0.0;
          final newUsed = currentUsed + amount;

          if (newUsed > budget) {
            final remaining = (budget - currentUsed).clamp(0, budget);
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Budget Exceeded!'),
                content: Text(
                  'You exceeded your $selectedCategory budget.\nRemaining: \$${remaining.toStringAsFixed(2)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Continue'),
                  ),
                ],
              ),
            );
          }

          // 🔁 Update category used amount
          await doc.reference.update({'used': newUsed});
        }
      }

      // ✅ Save or Update Expense
      if (widget.docId != null) {
        await expenseCollection.doc(widget.docId).update(newExpense);
      } else {
        await expenseCollection.add(newExpense);

        // Optional: Send notification to Firestore
        await userDoc.collection('users_notifications').add({
          'title': 'New Expense Added',
          'message': 'You added \$${amount.toStringAsFixed(2)} for "$title".',
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
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          widget.existingData != null ? "Edit Expense" : "Add Expense",
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(16),
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(width: 1.5, color: Colors.white),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        const Icon(Icons.calendar_today, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Expense Title",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    onChanged: (value) {
                      if (value != null)
                        setState(() => selectedCategory = value);
                    },
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading ? null : _submitExpense,
                      child: isLoading
                          ? const SpinKitFadingCircle(color: Colors.white)
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
          ),
        ),
      ),
    );
  }
}
