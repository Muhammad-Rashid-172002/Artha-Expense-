import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF1C1F26);
const Color kPrimaryDark2 = Color(0xFF2A2F3A);
const Color kPrimaryDark3 = Color(0xFF383C4C);

final LinearGradient kPrimaryGradient = const LinearGradient(
  colors: [kPrimaryDark2, kPrimaryDark3],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AiInsightsPage extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;

  const AiInsightsPage({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  String _insight =
      "Tap the button below to get insights about your spending habits.";
  bool _loading = false;

  // 🔹 Local AI-like logic (no API)
  String getLocalFinancialAdvice(double income, double expense) {
    // Safety conversion
    income = income.isNaN ? 0 : income;
    expense = expense.isNaN ? 0 : expense;

    // Prevent division by zero and handle negative values
    if (income <= 0) {
      return "⚠️ Please add your income to get financial insights.";
    }

    if (expense < 0) expense = 0;

    double balance = income - expense;
    double ratio = (expense / income) * 100;

    // Generate advice
    if (ratio < 40) {
      return "💰 Great job! You’re spending wisely — only ${ratio.toStringAsFixed(1)}% of your income is used.\n\n✅ Tip: Consider investing your extra savings for long-term growth.";
    } else if (ratio < 70) {
      return "📊 You’re doing okay — spending about ${ratio.toStringAsFixed(1)}% of your income.\n\n💡 Tip: Try saving at least 10–15% each month for emergencies.";
    } else if (ratio < 90) {
      return "⚠️ Your expenses are quite high (${ratio.toStringAsFixed(1)}% of your income).\n\n💰 Tip: Review your monthly subscriptions and cut unnecessary costs.";
    } else {
      return "🚨 Be careful! You’re spending ${ratio.toStringAsFixed(1)}% of your income.\n\n🔻 Tip: Try to lower expenses immediately or find ways to boost income.";
    }
  }

  void fetchInsight() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate processing
    final aiText = getLocalFinancialAdvice(
      widget.totalIncome,
      widget.totalExpense,
    );
    setState(() {
      _insight = aiText;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: kPrimaryGradient),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(
              "AI Insights",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "AI Financial Advice",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _insight,
                              key: ValueKey(_insight),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : fetchInsight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: kPrimaryDark2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 55),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        "Get AI Insights",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
