import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AddIncomeScreen extends StatefulWidget {
  final String? docId;
  final String? title;
  final String? amount;
  final Timestamp? createdAt;

  const AddIncomeScreen({
    super.key,
    this.docId,
    this.title,
    this.amount,
    this.createdAt,
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
    if (widget.title != null) _selectedSource = widget.title;
    if (widget.amount != null) _amountController.text = widget.amount!;
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

    final userId = FirebaseAuth.instance.currentUser!.uid;
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
      if (widget.docId != null) {
        await incomeRef.doc(widget.docId).update(incomeData);
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
      Navigator.pop(context);
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
              widget.docId == null ? 'Add Income' : 'Edit Income',
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
                            widget.docId == null
                                ? 'Save Income'
                                : 'Update Income',
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
