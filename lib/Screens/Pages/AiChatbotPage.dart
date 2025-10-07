import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final String _huggingFaceToken =
      ''; // Your Hugging Face token
  bool _isLoading = false;

  // Hugging Face API request
  Future<String> getAiResponse(String userMessage) async {
    try {
      final dio = Dio();

      final response = await dio.post(
       'https://api-inference.huggingface.co/models/google/flan-t5-small',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_huggingFaceToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "inputs":
              "You are an AI assistant for an expense tracker app. Only answer questions about income, expenses, budget, savings, or finance. If asked unrelated questions, respond politely that you cannot answer.\nUser: $userMessage\nAI:",
          "parameters": {"max_new_tokens": 200, "temperature": 0.7},
        },
      );

      // Hugging Face sometimes returns Map or List
      if (response.data is Map && response.data['generated_text'] != null) {
        return response.data['generated_text'].toString();
      } else if (response.data is List && response.data.isNotEmpty && response.data[0]['generated_text'] != null) {
        return response.data[0]['generated_text'].toString();
      } else {
        return " Unable to get AI response.";
      }
    } catch (e) {
      debugPrint('Hugging Face API error: $e');
      return " Unable to get AI response.";
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

    final aiReply = await getAiResponse(text);

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
          "AI Chatbot",
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
                        hintText: 'Ask about income, budget, savings...',
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
