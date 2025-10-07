import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==== COLORS ====
const Color kAppBarColor = Color(0xFF1565C0);
const Color kAppBarTextColor = Colors.white;
const Color kCardShadowColor = Colors.black26;
const Color kHeadingTextColor = Color(0xFF0D47A1);
const Color kSubtitleTextColor = Colors.black54;
const Color kButtonPrimary = Color(0xFF1565C0);

const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  final List<Map<String, String>> insights = [
    {
      'title': 'Daily Spending Analysis',
      'subtitle': 'AI predicts your spending habits and provides insights.',
      'details': 'Get a complete breakdown of your daily spending. AI will analyze your transactions, categorize them, and provide actionable insights to improve your financial habits.'
    },
    {
      'title': 'Income Trend',
      'subtitle': 'Track your income growth and get smart suggestions.',
      'details': 'Monitor your income over weeks, months, and years. AI suggests ways to optimize your income and detect irregular patterns.'
    },
    {
      'title': 'Budget Recommendations',
      'subtitle': 'AI suggests budget plans based on your expenses.',
      'details': 'AI calculates optimal budgets for each category based on your spending patterns, helping you save more efficiently.'
    },
    {
      'title': 'Savings Forecast',
      'subtitle': 'See how your savings will grow over time.',
      'details': 'Predict your future savings based on your current income and expenses. AI provides tips to maximize growth and achieve financial goals.'
    },
  ];

  void _navigateToDetail(Map<String, String> insight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsightDetailPage(insight: insight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      'AI Insights',
                      style: GoogleFonts.poppins(
                        color: kAppBarTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Insights List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ListView.separated(
                    itemCount: insights.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final insight = insights[index];
                      return InkWell(
                        onTap: () => _navigateToDetail(insight),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.blue.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: kCardShadowColor,
                                blurRadius: 6,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight['title']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kHeadingTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                insight['subtitle']!,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: kSubtitleTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: () => _navigateToDetail(insight),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kButtonPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: Text(
                                    'View',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightDetailPage extends StatelessWidget {
  final Map<String, String> insight;

  const InsightDetailPage({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(insight['title']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: kAppBarColor,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight['title']!,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: kHeadingTextColor),
              ),
              const SizedBox(height: 15),
              Text(
                insight['details']!,
                style: GoogleFonts.roboto(fontSize: 16, color: kSubtitleTextColor, height: 1.5),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
