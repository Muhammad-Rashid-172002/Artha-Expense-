import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/expanse/addexpanse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Map<String, IconData> categoryIcons = {
  'Food': Icons.restaurant,
  'Transport': Icons.directions_car,
  'Shopping': Icons.shopping_bag,
  'Home': Icons.home,
  'Bills': Icons.receipt,
  'Health': Icons.local_hospital,
  'Entertainment': Icons.movie,
  'Other': Icons.category,
};

class CategoryDetailsScreen extends StatefulWidget {
  final String category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  double totalAllExpenses = 0;

  Future<List<Map<String, dynamic>>> _fetchExpenses() async {
    if (userId == null) return [];

    try {
      final allSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .get();

      totalAllExpenses = allSnapshot.docs.fold(0, (sum, doc) {
        final amount = (doc.data()['amount'] ?? 0) as num;
        return sum + amount.toDouble();
      });

      final categorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users_expenses')
          .where('category', isEqualTo: widget.category)
          .get();

      List<Map<String, dynamic>> expenses = categorySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'amount': (data['amount'] ?? 0) as num,
          'createdAt': data['createdAt'], // may be null or Timestamp
          'category': data['category'] ?? 'Other',
        };
      }).toList();

      expenses.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate();
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return expenses;
    } catch (e) {
      print("🔥 Error fetching expenses: $e");
      return [];
    }
  }

  void _editExpense(Map<String, dynamic> expense) async {
    final updatedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddExpenseScreen(existingData: expense, docId: expense['id']),
      ),
    );

    if (updatedExpense != null) {
      setState(() {}); // reload after edit
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.category} Expenses",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const Center(child: Text("No expenses in this category."));
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final amount = expense['amount'] ?? 0;
              final title = expense['title'] ?? '';
              final category = expense['category'] ?? 'Other';

              final createdAt = expense['createdAt'];
              String formattedDate = 'Unknown Date';

              if (createdAt != null && createdAt is Timestamp) {
                try {
                  final date = createdAt.toDate();
                  formattedDate = DateFormat(
                    'dd MMM yyyy – hh:mm a',
                  ).format(date);
                } catch (e) {
                  print("⚠️ Date parsing error: $e");
                }
              }

              final percentage = totalAllExpenses > 0
                  ? ((amount / totalAllExpenses) * 100).toStringAsFixed(1)
                  : '0.0';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    categoryIcons[category] ?? Icons.category,
                    color: Colors.blue,
                  ),
                  title: Text(title),
                  subtitle: Text(formattedDate),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ' $amount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _editExpense(expense),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
