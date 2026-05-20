import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AcneFactsScreen extends StatefulWidget {
  const AcneFactsScreen({super.key});

  @override
  State<AcneFactsScreen> createState() => _AcneFactsScreenState();
}

class _AcneFactsScreenState extends State<AcneFactsScreen> {
  List<String> facts = [];
  bool isLoading = true;

  static const String geminiApiKey = "AIzaSyBQWo16qnqE9nVZe6NOi16NgY959g_pyOk";

  static const String url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$geminiApiKey";

  @override
  void initState() {
    super.initState();
    fetchFacts();
  }

  // 🔥 SAFE API CALL
  Future<void> fetchFacts() async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Give 6 short, interesting acne facts. Each on a new line.",
            },
          ],
        },
      ],
    };

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      // ✅ SAFE PARSING
      String text = "No facts found.";

      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["content"] != null &&
          data["candidates"][0]["content"]["parts"] != null &&
          data["candidates"][0]["content"]["parts"].isNotEmpty) {
        text = data["candidates"][0]["content"]["parts"][0]["text"];
      }

      final splitFacts = text.split("\n");

      if (!mounted) return;

      setState(() {
        facts = splitFacts.where((e) => e.trim().isNotEmpty).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        facts = ["Failed to load facts. Check internet/API."];
        isLoading = false;
      });
    }
  }

  // 🔹 UI CARD
  Widget factCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 132, 142, 250),
            Color.fromARGB(255, 13, 94, 135),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acne Facts"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchFacts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "💡 Did You Know?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...facts.map((fact) => factCard(fact)),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: fetchFacts,
                    child: const Text("Refresh Facts"),
                  ),
                ],
              ),
            ),
    );
  }
}
