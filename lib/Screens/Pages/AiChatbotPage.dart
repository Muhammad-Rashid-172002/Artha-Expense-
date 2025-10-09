import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==== COLORS ====
const Color kPrimaryDark1 = Color(0xFF1C1F26);
const Color kPrimaryDark2 = Color(0xFF2A2F3A);
const Color kPrimaryDark3 = Color(0xFF383C4C);
const Color kAccent = Color(0xFF00E676);

Color kUserMessageColor = Color(0xFF00E676).withOpacity(0.2);
Color kAiMessageColor = Color(0xFFFFFFFF).withOpacity(0.1);

class Aichatbotpage extends StatefulWidget {
  const Aichatbotpage({super.key});

  @override
  State<Aichatbotpage> createState() => _AichatbotpageState();
}

class _AichatbotpageState extends State<Aichatbotpage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ==== Improved keyword-based logic ====
  String getLocalResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    // Financial keyword variations (expanded list)
    final keywords = [
  "expense", "spend", "spending", "saving", "save", "money", "finance", 
  "financial", "income", "budget", "loan", "debt", "invest", "investment", 
  "investing", "profit", "loss", "salary", "earning", "earn", "bank", 
  "cash", "credit", "payment", "goal", "fund", "balance", "tax", "wealth",
  "retirement", "insurance", "portfolio", "interest", "inflation",
  "assets", "liabilities", "capital", "stock", "market", "dividend",
  "expense tracking", "savings plan", "mutual fund", "crypto", "nft",
  "mortgage", "emi", "pension", "bills", "budgeting", "financial freedom"
];

bool isFinancial = keywords.any((word) => msg.toLowerCase().contains(word));

if (isFinancial) {
  final responses = [
    "💰 That’s a smart financial thought! Always plan your spending and savings wisely.",
    "📊 Diversify your investments — never rely on a single source of income or profit.",
    "💡 Try following the 50/30/20 rule: 50% needs, 30% wants, and 20% savings.",
    "🏦 Building a small emergency fund can help you avoid loans or credit card debt in tough times.",
    "📈 Regularly tracking your expenses helps you discover hidden spending patterns.",
    "💳 Paying your credit card bills on time improves your credit score and saves on interest.",
    "💼 Investing early — even small amounts — can lead to big returns over time through compounding.",
    "💸 Set realistic monthly goals for saving and review your progress weekly.",
    "🔑 The key to financial growth is consistency — small actions every day matter.",
    "📆 Automate your savings each month to stay disciplined without extra effort.",
    "🪙 Reinvest your profits instead of spending them — that’s how wealth compounds.",
    "📉 Avoid emotional decisions in investing — patience beats panic.",
    "📚 Educate yourself about financial literacy — knowledge compounds faster than money.",
    "💎 Don't chase trends — build long-term value through sustainable financial habits.",
    "💼 Before investing, pay off high-interest debts — they grow faster than your investments.",
    "🧾 Review your income and expense reports monthly to understand your financial flow.",
    "🌱 Invest in yourself — new skills often bring better earning opportunities.",
    "💬 Set SMART goals: Specific, Measurable, Achievable, Relevant, Time-bound.",
    "💰 Create multiple income streams — one salary isn’t enough for financial freedom.",
    "🚀 Focus on your goals, not just income. Savings, control, and patience matter most.",
    "💸 Budgeting isn’t about restriction — it’s about freedom and control over your finances.",
    "🧠 Remember: Saving is good, but smart investing turns savings into wealth.",
    "📉 Track your liabilities — financial awareness is the first step toward freedom.",
    "💼 Your budget tells your money where to go instead of wondering where it went.",
    "🏡 Save for assets that appreciate, not liabilities that depreciate.",
    "💡 If you want to grow financially, start by understanding your cash flow every month."
  ];

  responses.shuffle();
  return responses.first;
}

    
    else {
      return "🤖 I have no response to this question as it’s not related to finance.";
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': text});
      _controller.clear();
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800)); // fake delay
    final aiReply = getLocalResponse(text);

    setState(() {
      _messages.add({'sender': 'ai', 'message': aiReply});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark1,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "AI Insights",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kPrimaryDark2,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              colors: [
                                kAccent.withOpacity(0.3),
                                kAccent.withOpacity(0.15),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.05),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message['message']!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about income, budget, or savings...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white54),
                        filled: true,
                        fillColor: kPrimaryDark2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kAccent,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                          child: const Icon(Icons.send, color: Colors.black),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
