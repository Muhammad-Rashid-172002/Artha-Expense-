import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ==== COLORS ====
const Color kAppBarColor = Color(0xFF1565C0); // Deep Blue
const Color kAppBarTextColor = Colors.white; // White text
const Color kBalanceCardColor = Color(0xFFFFD700); // Gold
const Color kCardColor = Colors.white;
const Color kCardTextColor = Colors.black87;
const Color kHeadingTextColor = Color(0xFF0D47A1); // Dark Blue
const Color kSubtitleTextColor = Colors.black87;
const Color kBodyTextColor = Colors.black54;
const Color kFadedTextColor = Colors.grey;
const Color kButtonPrimary = Color(0xFF1565C0); // Deep Blue
const Color kButtonPrimaryText = Colors.white;
const Color kButtonSecondaryBorder = Color(0xFFFFD700); // Gold
const Color kButtonSecondaryText = Color(0xFF1565C0);
const Color kButtonDisabled = Color(0xFFBDBDBD);
const Color kButtonDisabledText = Color(0xFF757575);

/// ✅ Guest storage (temporary, in-memory)
class GuestIncomeStore {
  static final List<Map<String, dynamic>> _incomes = [];

  static List<Map<String, dynamic>> get incomes =>
      List<Map<String, dynamic>>.from(_incomes)..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

  static void addIncome({required String title, required double amount}) {
    _incomes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'amount': amount,
      'date': DateTime.now(),
    });
  }

  static void editIncome({
    required String id,
    required String title,
    required double amount,
  }) {
    final idx = _incomes.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _incomes[idx] = {
        'id': id,
        'title': title,
        'amount': amount,
        'date': DateTime.now(),
      };
    }
  }

  static void deleteIncome(String id) {
    _incomes.removeWhere((r) => r['id'] == id);
  }

  static double get totalIncome {
    return _incomes.fold(
      0,
      (sum, item) =>
          sum +
          (item['amount'] is num ? (item['amount'] as num).toDouble() : 0),
    );
  }
}

class AddIncomeScreen extends StatefulWidget {
  final String? incomeId;
  final String? initialTitle;
  final double? initialAmount;
  final DateTime? initialDate;
  final bool isEditing;
  final bool isGuest;
  final void Function(String title, double amount)? onIncomeAdded;

  const AddIncomeScreen({
    super.key,
    this.incomeId,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
    this.isEditing = false,
    this.isGuest = false,
    this.onIncomeAdded,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedSource;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _incomeSources = [
    {'label': 'Salary', 'icon': Icons.monetization_on},
    {'label': 'Bonus', 'icon': Icons.card_giftcard},
    {'label': 'Freelance', 'icon': Icons.laptop_mac},
    {'label': 'Investment', 'icon': Icons.show_chart},
    {'label': 'Other', 'icon': Icons.attach_money},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _selectedSource = widget.initialTitle;
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toString();
    }
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (_selectedSource == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Please select a valid income source and enter a positive amount.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Guest mode
    if (widget.isGuest) {
      if (!widget.isEditing) {
        GuestIncomeStore.addIncome(title: _selectedSource!, amount: amount);
      } else {
        GuestIncomeStore.editIncome(
          id: widget.incomeId!,
          title: _selectedSource!,
          amount: amount,
        );
      }

      widget.onIncomeAdded?.call(_selectedSource!, amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Income saved (Guest Mode)'),
          backgroundColor: Colors.blue,
        ),
      );

      Navigator.pop(context, true);
      setState(() => _isLoading = false);
      return;
    }

    // Firebase mode
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("❌ Not logged in. Please sign in."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final userId = user.uid;
    final incomeData = {
      'title': _selectedSource,
      'amount': amount,
      'createdAt': Timestamp.now(),
    };

    final incomeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_income');

    try {
      if (widget.isEditing && widget.incomeId != null) {
        await incomeRef.doc(widget.incomeId).update(incomeData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Income updated successfully.'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        await incomeRef.add(incomeData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Income added successfully.'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      widget.onIncomeAdded?.call(_selectedSource!, amount);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save income: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kAppBarColor.withOpacity(0.1),
              kBalanceCardColor.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.isEditing ? 'Edit Income' : 'Add Income',
              style: TextStyle(
                color: kAppBarTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: kAppBarColor,
            centerTitle: true,
            elevation: 4,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Income Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kHeadingTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedSource,
                    items: _incomeSources.map((source) {
                      return DropdownMenuItem<String>(
                        value: source['label'],
                        child: Row(
                          children: [
                            Icon(source['icon'], color: kButtonPrimary),
                            const SizedBox(width: 10),
                            Text(
                              source['label'],
                              style: TextStyle(color: kBodyTextColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSource = value),
                    decoration: InputDecoration(
                      labelText: 'Select Income Source',
                      labelStyle: TextStyle(color: kButtonPrimary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kButtonPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kButtonPrimary, width: 2),
                      ),
                    ),
                    dropdownColor: kCardColor,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: kBodyTextColor),
                    decoration: InputDecoration(
                      labelText: 'Enter Amount',
                      labelStyle: TextStyle(color: kButtonPrimary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kButtonPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kButtonPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? SpinKitFadingCircle(color: kButtonPrimary, size: 40)
                      : ElevatedButton.icon(
                          onPressed: _saveIncome,
                          icon: const Icon(Icons.save),
                          label: Text(
                            widget.isEditing ? 'Update Income' : 'Save Income',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonPrimary,
                            foregroundColor: kButtonPrimaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
