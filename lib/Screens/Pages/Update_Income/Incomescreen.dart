import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/AddIncomescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

/// Temporary storage for guest incomes (in-memory)
class GuestIncomeStore {
  static final List<Map<String, dynamic>> _incomes = [];

  static List<Map<String, dynamic>> get incomes =>
      List<Map<String, dynamic>>.from(_incomes)..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

  static void addIncome({
    required String title,
    required double amount,
    required DateTime date,
  }) {
    _incomes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'amount': amount,
      'date': date,
    });
  }

  static void editIncome({
    required String id,
    required String title,
    required double amount,
    required DateTime date,
  }) {
    final idx = _incomes.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      _incomes[idx] = {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date,
      };
    }
  }

  static void deleteIncome(String id) {
    _incomes.removeWhere((r) => r['id'] == id);
  }
}

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // ---------- Firestore helpers ----------
  Future<void> _deleteIncome(String id) async {
    final uid = currentUser?.uid;
    if (uid == null) return; // Guest: ignore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users_incomes')
        .doc(id)
        .delete();
  }

  void _editIncome(DocumentSnapshot incomeDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          isEditing: true,
          incomeId: incomeDoc.id,
          initialTitle: incomeDoc['title'],
          initialAmount: incomeDoc['amount'].toDouble(),
          initialDate: (incomeDoc['date'] as Timestamp).toDate(),
        ),
      ),
    );
  }

  void _navigateToAddIncome() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
    );
  }

  // ---------- Guest mode: add/edit dialog ----------
  Future<void> _openGuestIncomeDialog({Map<String, dynamic>? initial}) async {
    final titleCtrl = TextEditingController(text: initial?['title'] ?? '');
    final amountCtrl = TextEditingController(
      text: initial?['amount']?.toString() ?? '',
    );
    DateTime selectedDate = (initial?['date'] as DateTime?) ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.green,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    initial == null ? 'Add Income (Guest)' : 'Edit Income',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(color: Colors.black87),
                      filled: true,
                      fillColor: Colors.amber[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: const TextStyle(color: Colors.black87),
                      filled: true,
                      fillColor: Colors.amber[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amberAccent),
                          ),
                          child: Text(
                            DateFormat.yMMMd().format(selectedDate),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModal(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final amountText = amountCtrl.text.trim();
                        if (title.isEmpty || amountText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title and Amount required'),
                            ),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountText) ?? 0.0;
                        if (initial == null) {
                          GuestIncomeStore.addIncome(
                            title: title,
                            amount: amount,
                            date: selectedDate,
                          );
                        } else {
                          GuestIncomeStore.editIncome(
                            id: initial['id'] as String,
                            title: title,
                            amount: amount,
                            date: selectedDate,
                          );
                        }
                        Navigator.pop(context);
                        setState(() {}); // refresh list
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(initial == null ? 'Save Income' : 'Update'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteIncome(
    String incomeId, {
    bool isGuest = false,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Income",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this income?",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.amber[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (isGuest) {
        GuestIncomeStore.deleteIncome(incomeId);
        if (!mounted) return;
        setState(() {});
      } else {
        await _deleteIncome(incomeId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Income deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = currentUser == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Incomes",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        tooltip: 'Add Income',
        onPressed: _isLoading
            ? null
            : (isGuest ? () => _openGuestIncomeDialog() : _navigateToAddIncome),
        child: _isLoading
            ? const SpinKitCircle(color: Colors.white, size: 24)
            : const Icon(Icons.add, color: Colors.blueGrey),
      ),
      body: isGuest ? _buildGuestList() : _buildFirestoreList(currentUser!.uid),
    );
  }

  // ---------- Guest list ----------
  Widget _buildGuestList() {
    final incomes = GuestIncomeStore.incomes;
    if (incomes.isEmpty) {
      return const Center(
        child: Text(
          "No incomes added yet (Guest).",
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: incomes.length,
      itemBuilder: (context, index) {
        final income = incomes[index];
        final date = income['date'] as DateTime;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade200, // lighter green for top
                Colors.green.shade700, // darker green for bottom
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: Colors.transparent, // make card transparent to show gradient
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.white),
              title: Text(
                income['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Amount: ${income['amount']}\n${DateFormat.yMMMd().format(date)}",
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                color: Colors.green,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openGuestIncomeDialog(initial: income);
                  } else if (value == 'delete') {
                    _confirmDeleteIncome(income['id'] as String, isGuest: true);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Firestore list ----------
  Widget _buildFirestoreList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_incomes')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SpinKitCircle(color: Colors.green));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No incomes added yet.",
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final incomes = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: incomes.length,
          itemBuilder: (context, index) {
            final income = incomes[index];
            final date = (income['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromARGB(255, 57, 134, 60), Colors.green],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.white),
                  title: Text(
                    income['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Amount: ${income['amount']}\n${DateFormat.yMMMd().format(date)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    color: Colors.green,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editIncome(income);
                      } else if (value == 'delete') {
                        _confirmDeleteIncome(income.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
