import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expanse_tracker_app/Screens/Pages/Update_Income/AddIncomescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF0F2027);
const Color kPrimaryDark2 = Color(0xFF203A43);
const Color kPrimaryDark3 = Color(0xFF2C5364);
const Color kButtonPrimary = Color(0xFF1565C0);
const Color kButtonPrimaryText = Colors.white;
const Color kCardTextColor = Colors.white;
const Color kBodyTextColor = Colors.white70;
const Color kFadedTextColor = Colors.grey;

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
  String? userId;

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
        backgroundColor: kPrimaryDark2,
        title: Text(
          'Delete Income',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: kButtonPrimaryText,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this income?',
          style: GoogleFonts.roboto(color: kBodyTextColor, fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kFadedTextColor),
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
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

      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Income deleted successfully!',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
          onIncomeAdded: (title, amount) => setState(() {}),
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
          colors: [kPrimaryDark1, kPrimaryDark2, kPrimaryDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kButtonPrimaryText),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Income',
            style: GoogleFonts.playfairDisplay(
              color: kButtonPrimaryText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: userId == null ? _buildGuestView() : _buildFirebaseView(),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white10,
                blurRadius: 4,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor:
                Colors.transparent, // Gradient handled by parent container
            tooltip: 'Add Income',
            onPressed: _openAddIncome,
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
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
                    style: GoogleFonts.roboto(
                      color: kButtonPrimaryText,
                      fontSize: 16,
                    ),
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
                            backgroundColor: Colors.redAccent,
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
                        ),
                        color: kPrimaryDark2,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1C1F26), Color(0xFF2A2F3A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white10,
                                blurRadius: 3,
                                offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ==== Left: Icon + Details ====
                              Row(
                                children: [
                                  // Icon container with soft gradient background
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0F2027),
                                          Color(0xFF203A43),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.tealAccent.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.attach_money_rounded,
                                      color: Colors.tealAccent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // ==== Title + Date ====
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        income['title'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // ==== Right: Amount ====
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.tealAccent.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  '${income['amount']}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
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
                  ? Center(
                      child: Text(
                        'No income added yet.',
                        style: GoogleFonts.roboto(
                          color: kButtonPrimaryText,
                          fontSize: 16,
                        ),
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
                                backgroundColor: Colors.redAccent,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => _editIncome(doc),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1C1F26),
                                    Color(0xFF2A2F3A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white12,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white10,
                                    blurRadius: 3,
                                    offset: Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // ==== Left side: Icon + Info ====
                                  Row(
                                    children: [
                                      // Money icon in glowing box
                                      Container(
                                        height: 48,
                                        width: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0F2027),
                                              Color(0xFF203A43),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.tealAccent
                                                  .withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.attach_money_rounded,
                                          color: Colors.tealAccent,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Title and Date
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // ==== Right side: Amount ====
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.tealAccent.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${amount}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1F26), Color(0xFF2A2F3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white10,
            blurRadius: 3,
            offset: Offset(-2, -2),
          ),
        ],
        border: Border.all(color: Colors.white12, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.tealAccent.shade100,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Income',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${totalIncome.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.tealAccent.withOpacity(0.5),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
