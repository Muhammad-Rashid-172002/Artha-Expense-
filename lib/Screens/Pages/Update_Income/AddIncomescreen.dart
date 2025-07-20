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
    if (widget.title != null) {
      _selectedSource = widget.title;
    }
    if (widget.amount != null) {
      _amountController.text = widget.amount!;
    }
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (_selectedSource == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid source and amount.')),
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
        // Update existing income
        await incomeRef.doc(widget.docId).update(incomeData);
      } else {
        // Add new income
        await incomeRef.add(incomeData);
      }
      Navigator.pop(context); // Close the screen after saving
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save income: $e')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docId == null ? 'Add Income' : 'Edit Income',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Income Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedSource,
                  items: _incomeSources.map((source) {
                    return DropdownMenuItem<String>(
                      value: source['label'],
                      child: Row(
                        children: [
                          Icon(source['icon'], color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(source['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSource = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Income Source',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter Amount',
                    border: OutlineInputBorder(),
                  ),
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
                        onPressed: _saveIncome,
                        icon: const Icon(Icons.save),
                        label: Text(
                          widget.docId == null
                              ? 'Save Income'
                              : 'Update Income',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
