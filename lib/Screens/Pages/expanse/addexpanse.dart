import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Temporary storage for guest users (global list)
List<Map<String, dynamic>> guestExpenses = [];

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;
  final bool isGuest;
  final void Function(Map<String, dynamic> expense)? onExpenseAdded;

  const AddExpenseScreen({
    super.key,
    this.existingData,
    this.docId,
    this.isGuest = false,
    this.onExpenseAdded,
  });

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
      "docId": widget.docId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final user = FirebaseAuth.instance.currentUser;

    try {
      if (widget.isGuest || user == null) {
        // Guest Mode → Save locally
        if (widget.docId != null) {
          final idx = guestExpenses.indexWhere(
            (exp) => exp['docId'] == widget.docId,
          );
          if (idx != -1) guestExpenses[idx] = newExpense;
        } else {
          guestExpenses.add(newExpense);
        }

        guestExpenses.sort(
          (a, b) => (b['timestamp'] as Timestamp).compareTo(
            a['timestamp'] as Timestamp,
          ),
        );

        widget.onExpenseAdded?.call(newExpense);

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

        widget.onExpenseAdded?.call(newExpense);

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
      labelStyle: TextStyle(color: kSubtitleTextColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kCardTextColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kButtonPrimary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.existingData != null ? "Edit Expense" : "Add Expense",
          style: const TextStyle(color: kAppBarTextColor),
        ),
        centerTitle: true,
        backgroundColor: kAppBarColor,
        elevation: 3,
      ),
      body: Center(
        child: SingleChildScrollView(
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
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: kButtonPrimary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: titleController,
                      label: "Expense Title",
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: amountController,
                      label: "Amount",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: _boxDecoration(),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        dropdownColor: kBalanceCardColor,
                        style: const TextStyle(
                          color: kCardTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        iconEnabledColor: kButtonPrimary,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(categoryIcons[cat], color: kButtonPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    color: kCardTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: "Category",
                          labelStyle: TextStyle(color: kHeadingTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: kBalanceCardColor,
                          backgroundColor: kButtonPrimary,
                        ),
                        onPressed: isLoading ? null : _submitExpense,
                        child: isLoading
                            ? const SpinKitFadingCircle(
                                color: kButtonPrimaryText,
                                size: 28,
                              )
                            : Text(
                                widget.existingData != null
                                    ? "SAVE CHANGES"
                                    : "ADD EXPENSE",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kButtonPrimaryText,
                                ),
                              ),
                      ),
                    ),
                  ],
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
    return Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: kCardTextColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kHeadingTextColor),
          prefixIcon: Icon(icon, color: kButtonPrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: kBalanceCardColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: kBalanceCardColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
