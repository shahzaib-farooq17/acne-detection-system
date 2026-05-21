import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AcneChatbotScreen extends StatefulWidget {
  const AcneChatbotScreen({super.key});

  @override
  State<AcneChatbotScreen> createState() => _AcneChatbotScreenState();
}

class _AcneChatbotScreenState extends State<AcneChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool isTyping = false;

  static const String geminiApiKey = "API key";

  static const String geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$geminiApiKey";

  // ---------------- GEMINI API ----------------
  Future<String> geminiReply(String userMessage) async {
    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Act as a professional dermatology assistant. "
                  "Provide professional, concise, and user-friendly advice for acne care. "
                  "Keep response short, helpful, and under 80 words. "
                  "Query: $userMessage",
            },
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "Error ${response.statusCode}: Unable to get response.";
      }
    } catch (e) {
      return "Network error. Please try again.";
    }
  }

  // ---------------- SEND MESSAGE ----------------
  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, {"fromUser": true, "text": text});
      _controller.clear();
      isTyping = true;
    });

    final reply = await geminiReply(text);

    setState(() {
      _messages.insert(0, {"fromUser": false, "text": reply});
      isTyping = false;
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f1f1),
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 68, 138, 255),
                  Color.fromARGB(255, 68, 138, 255),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 15),
                const CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage("assets/images/bot.png"),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Acne Care Bot",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "AI Dermatology Assistant",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CHAT
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["fromUser"];

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xff4fa3d1) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg["text"],
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isTyping)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Bot is typing...",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xfff1f7fa),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about acne care...",
                      filled: true,
                      fillColor: const Color(0xffe3edf3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xff4fa3d1),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
