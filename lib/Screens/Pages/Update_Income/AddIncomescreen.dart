import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// ✅ Guest storage (temporary, in-memory)
class GuestIncomeStore {
  static final List<Map<String, dynamic>> _incomes = [];

  static List<Map<String, dynamic>> get incomes =>
      List<Map<String, dynamic>>.from(_incomes)..sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );

  static void addIncome({required String title, required double amount}) {
    _incomes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'amount': amount,
      'createdAt': DateTime.now(),
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
        'createdAt': DateTime.now(),
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

  const AddIncomeScreen({
    super.key,
    this.incomeId,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
    this.isEditing = false,
    this.isGuest = false,
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
        const SnackBar(
          content: Text(
            '⚠️ Please select a valid income source and enter a positive amount.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ✅ Guest mode
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Income saved (Guest Mode)'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // return true to refresh
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Firebase mode
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Not logged in. Please sign in."),
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
          const SnackBar(
            content: Text('✅ Income updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await incomeRef.add(incomeData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Income added successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 248, 222, 137)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.isEditing ? 'Edit Income' : 'Add Income',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green.shade700,
            centerTitle: true,
            elevation: 4,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Income Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                            Icon(source['icon'], color: Colors.green),
                            const SizedBox(width: 10),
                            Text(
                              source['label'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSource = value),
                    decoration: InputDecoration(
                      labelText: 'Select Income Source',
                      labelStyle: const TextStyle(color: Colors.green),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                    dropdownColor: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Enter Amount',
                      labelStyle: const TextStyle(color: Colors.green),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const SpinKitFadingCircle(color: Colors.green, size: 40)
                      : ElevatedButton.icon(
                          onPressed: _saveIncome,
                          icon: const Icon(Icons.save),
                          label: Text(
                            widget.isEditing ? 'Update Income' : 'Save Income',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
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
