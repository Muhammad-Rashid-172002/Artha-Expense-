import 'package:expanse_tracker_app/Screens/Pages/Update_income/Incomescreen.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/totalExpanse.dart'
    hide kButtonPrimary, kCardTextColor, kButtonPrimaryText;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '⚠️ Please enter a valid title and amount',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFFF4B2B),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '❌ Failed to save expense',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFFF4B2B),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.redAccent),
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

  Widget _buildCalendar() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.redAccent),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.existingData != null ? "Edit Expense" : "Add Expense",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 3,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            dropdownColor: Colors.white,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            iconEnabledColor: Colors.redAccent,
                            onChanged: (value) {
                              if (value != null)
                                setState(() => selectedCategory = value);
                            },
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      categoryIcons[cat],
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: "Category",
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
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
                            onPressed: isLoading ? null : _submitExpense,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Colors.redAccent,
                              elevation: 8,
                              shadowColor: Colors.redAccent.withOpacity(0.5),
                            ),
                            child: isLoading
                                ? const SpinKitFadingCircle(
                                    color: Colors.white,
                                    size: 28,
                                  )
                                : Text(
                                    widget.existingData != null
                                        ? "SAVE CHANGES"
                                        : "ADD EXPENSE",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
        ),
      ),
    );
  }
}
