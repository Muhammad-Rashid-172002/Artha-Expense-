import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: const Color(
            0xFF2C5364,
          ), // matches your gradient tone
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '⚠️ Please select a valid income source and enter a positive amount.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(seconds: 3),
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: const Color(0xFF203A43), // Deep gradient tone
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '✅ Income saved (Guest Mode)',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 3),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: const Color(0xFF0F2027), // gradient tone
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              '✅ Income updated successfully.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        await incomeRef.add(incomeData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: const Color(0xFF203A43), // matches your gradient
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              '✅ Income added successfully.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      widget.onIncomeAdded?.call(_selectedSource!, amount);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.redAccent.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '❌ Failed to save income: $e',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.isEditing ? 'Edit Income' : 'Add Income',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Income Details',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ===== Income Source Dropdown =====
                  DropdownButtonFormField<String>(
                    value: _selectedSource,
                    items: _incomeSources.map((source) {
                      return DropdownMenuItem<String>(
                        value: source['label'],
                        child: Row(
                          children: [
                            Icon(source['icon'], color: Colors.white70),
                            const SizedBox(width: 10),
                            Text(
                              source['label'],
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSource = value),
                    decoration: InputDecoration(
                      labelText: 'Select Income Source',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1E1E2C),
                  ),

                  const SizedBox(height: 20),

                  // ===== Amount Field =====
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter Amount',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== Save Button or Loader =====
                  _isLoading
                      ? const SpinKitFadingCircle(color: Colors.white, size: 45)
                      : ElevatedButton.icon(
                          onPressed: _saveIncome,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            widget.isEditing ? 'Update Income' : 'Save Income',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent.withOpacity(
                                  0.35,
                                ),
                                shadowColor: Colors.tealAccent.withOpacity(0.6),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 42,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.all(
                                  Colors.tealAccent.withOpacity(0.2),
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
