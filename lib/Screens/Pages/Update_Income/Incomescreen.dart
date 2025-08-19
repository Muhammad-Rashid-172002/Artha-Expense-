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
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deleteIncome(String docId) async {
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
          .doc(docId)
          .delete();
    }
  }

  void _editIncome(DocumentSnapshot doc) {
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
      body: StreamBuilder<QuerySnapshot>(
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
            final amount =
                double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
            totalIncome += amount;
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              // Blue circular total income container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 69, 68, 68),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white, // Border color
                    width: 1.5, // Border width
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ' ${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                              color: Colors.grey[850], // Card background color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ), // Border color and width
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.attach_money,
                                  color: Colors.amber,
                                ), // Optional: icon color
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ), // Text color
                                ),
                                subtitle: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ), // Subtitle text
                                ),
                                trailing: Text(
                                  ' $amount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ), // Amount text
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        tooltip: 'Add Income',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
