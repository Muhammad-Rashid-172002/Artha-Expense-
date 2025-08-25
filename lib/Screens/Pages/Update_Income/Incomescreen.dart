import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/AddIncomescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String? userId; // null if guest
  List<Map<String, dynamic>> guestIncomes = []; // guest storage

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _deleteIncome(String id) async {
    if (userId == null) {
      setState(() {
        guestIncomes.removeWhere((income) => income['id'] == id);
      });
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to delete this income?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_income')
          .doc(id)
          .delete();
    }
  }

  void _editIncome(DocumentSnapshot doc) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guest mode: Edit not available")),
      );
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final amount = data['amount']?.toString() ?? '0';
    final createdAt = data['createdAt'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          docId: doc.id,
          title: title,
          amount: amount,
          createdAt: createdAt,
        ),
      ),
    );
  }

  void _addGuestIncome(String title, double amount) {
    setState(() {
      guestIncomes.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'amount': amount,
        'createdAt': DateTime.now(),
      });
    });
  }

  void _openAddIncome() {
    if (userId == null) {
      // Guest: simple dialog
      final titleController = TextEditingController();
      final amountController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900], // Background color
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Colors.white,
              width: 2,
            ), // White border
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          title: const Text(
            "Add Income",
            style: TextStyle(color: Colors.white), // Title text color
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (titleController.text.isNotEmpty && amount > 0) {
                  _addGuestIncome(titleController.text.trim(), amount);
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.blue), // Button text color
              ),
            ),
          ],
        ),
      );
    } else {
      // Logged-in: go to Firebase AddIncomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Income',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: userId == null ? _buildGuestView() : _buildFirebaseView(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        tooltip: 'Add Income',
        onPressed: _openAddIncome,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // -------- Guest Mode UI ----------
  Widget _buildGuestView() {
    double totalIncome = 0;
    for (var income in guestIncomes) {
      totalIncome += income['amount'] as double;
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTotalIncomeCard(totalIncome),
        const SizedBox(height: 16),
        Expanded(
          child: guestIncomes.isEmpty
              ? const Center(
                  child: Text(
                    'No income added yet (Guest Mode)',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: guestIncomes.length,
                  itemBuilder: (context, index) {
                    final income = guestIncomes[index];
                    final formattedDate = DateFormat.yMMMd().format(
                      income['createdAt'],
                    );

                    return Slidable(
                      key: ValueKey(income['id']),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deleteIncome(income['id']),
                            backgroundColor: Colors.red,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.attach_money,
                            color: Colors.amber,
                          ),
                          title: Text(
                            income['title'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            formattedDate,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            '${income['amount']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------- Firebase Mode UI ----------
  Widget _buildFirebaseView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_income')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final incomeDocs = snapshot.data?.docs ?? [];

        double totalIncome = 0;
        for (var doc in incomeDocs) {
          final data = doc.data() as Map<String, dynamic>;
          totalIncome +=
              double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildTotalIncomeCard(totalIncome),
            const SizedBox(height: 16),
            Expanded(
              child: incomeDocs.isEmpty
                  ? const Center(
                      child: Text(
                        'No income added yet.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: incomeDocs.length,
                      itemBuilder: (context, index) {
                        final doc = incomeDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'No Title';
                        final amount = data['amount']?.toString() ?? '0';
                        final date = (data['createdAt'] as Timestamp?)
                            ?.toDate();
                        final formattedDate = date != null
                            ? DateFormat.yMMMd().format(date)
                            : '';

                        return Slidable(
                          key: ValueKey(doc.id),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.50,
                            children: [
                              SlidableAction(
                                onPressed: (_) => _editIncome(doc),
                                backgroundColor: Colors.green,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: (_) => _deleteIncome(doc.id),
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.grey[850],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.attach_money,
                                color: Colors.amber,
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                formattedDate,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                ' $amount',
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () => _editIncome(doc),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalIncomeCard(double totalIncome) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 69, 68, 68),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'Total Income',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            totalIncome.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
