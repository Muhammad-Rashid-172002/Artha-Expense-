import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/AddIncomescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ==== COLORS ====
const Color kAppBarColor = Color(0xFF1565C0); // Deep Blue
const Color kAppBarTextColor = Colors.white; // White text
const Color kBalanceCardColor = Color(0xFFFFD700); // Gold
const Color kBalanceCardTextColor = Colors.black; // Black text on gold
const Color kCardColor = Colors.white; // White background
const Color kCardTextColor = Colors.black87; // Dark text
const Color kHeadingTextColor = Color(0xFF0D47A1); // Dark Blue heading
const Color kSubtitleTextColor = Colors.black87; // Subtitles
const Color kBodyTextColor = Colors.black54; // Regular body text
const Color kFadedTextColor = Colors.grey; // Faded/secondary
const Color kButtonPrimary = Color(0xFF1565C0); // Deep Blue background
const Color kButtonPrimaryText = Colors.white; // White text
const Color kButtonSecondaryBorder = Color(0xFFFFD700); // Gold border
const Color kButtonSecondaryText = Color(0xFF1565C0); // Blue text
const Color kButtonDisabled = Color(0xFFBDBDBD); // Gray background
const Color kButtonDisabledText = Color(0xFF757575); // Light gray text

/// ✅ Guest Income Store (local-only)
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
  final bool isGuest;
  final Function(Map<String, dynamic>)? onIncomeAdded;

  const IncomeScreen({super.key, this.isGuest = false, this.onIncomeAdded});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String? userId; // null = guest mode

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _deleteIncome(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kCardColor,
        title: Text(
          'Delete Income',
          style: TextStyle(fontWeight: FontWeight.bold, color: kCardTextColor),
        ),
        content: Text(
          'Are you sure you want to delete this income?',
          style: TextStyle(color: kBodyTextColor),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kFadedTextColor),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (userId == null) {
        setState(() {
          GuestIncomeStore.deleteIncome(id);
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('users_income')
            .doc(id)
            .delete();
      }
    }
  }

  void _editIncome(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          incomeId: doc.id,
          initialTitle: data['title'],
          initialAmount: double.tryParse(data['amount'].toString()) ?? 0.0,
          initialDate: (data['createdAt'] as Timestamp?)?.toDate(),
          isEditing: true,
          isGuest: false,
          onIncomeAdded: (title, amount) {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _editGuestIncome(Map<String, dynamic> income) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          incomeId: income['id'],
          initialTitle: income['title'],
          initialAmount: income['amount'] as double,
          initialDate: income['date'] as DateTime,
          isEditing: true,
          isGuest: true,
          onIncomeAdded: (title, amount) {
            setState(() {
              GuestIncomeStore.editIncome(
                id: income['id'],
                title: title,
                amount: amount,
                date: DateTime.now(),
              );
            });
          },
        ),
      ),
    );
  }

  void _openAddIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          isGuest: userId == null,
          onIncomeAdded: (title, amount) {
            if (userId == null) {
              setState(() {
                GuestIncomeStore.addIncome(
                  title: title,
                  amount: amount,
                  date: DateTime.now(),
                );
              });
            } else {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFE8F5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: kAppBarColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Income',
            style: GoogleFonts.playfairDisplay(
              color: kAppBarTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: userId == null ? _buildGuestView() : _buildFirebaseView(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kButtonPrimary,
          tooltip: 'Add Income',
          onPressed: _openAddIncome,
          child: const Icon(Icons.add, color: kButtonPrimaryText),
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    final incomes = GuestIncomeStore.incomes;
    double totalIncome = incomes.fold(
      0,
      (sum, i) => sum + (i['amount'] as double),
    );

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTotalIncomeCard(totalIncome),
        const SizedBox(height: 16),
        Expanded(
          child: incomes.isEmpty
              ? Center(
                  child: Text(
                    'No income added yet (Guest Mode)',
                    style: TextStyle(color: kCardTextColor),
                  ),
                )
              : ListView.builder(
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    final formattedDate = DateFormat.yMMMd().format(
                      income['date'] as DateTime,
                    );

                    return Slidable(
                      key: ValueKey(income['id']),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.50,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _editGuestIncome(income),
                            backgroundColor: kButtonPrimary,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: kButtonPrimary, width: 1.5),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kButtonPrimary, Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.attach_money,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              income['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              '${income['amount']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
          final amt = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
          totalIncome += amt;
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildTotalIncomeCard(totalIncome),
            const SizedBox(height: 16),
            Expanded(
              child: incomeDocs.isEmpty
                  ? Center(
                      child: Text(
                        'No income added yet.',
                        style: TextStyle(color: kCardTextColor),
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
                                backgroundColor: kButtonPrimary,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: kButtonPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kButtonPrimary, Color(0xFF1B5E20)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Text(
                                  amount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _editIncome(doc),
                              ),
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
        gradient: LinearGradient(
          colors: [kButtonPrimary, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kButtonPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Income',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalIncome.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
