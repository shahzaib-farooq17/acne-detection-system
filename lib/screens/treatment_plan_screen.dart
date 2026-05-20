import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TreatmentPlanScreen extends StatefulWidget {
  const TreatmentPlanScreen({super.key, required String acneType, required String skinType});

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  String? plan;
  String? acneType;
  String? skinType;
  bool isLoading = true;

  static const String geminiApiKey = "AIzaSyBQWo16qnqE9nVZe6NOi16NgY959g_pyOk";

  static const String geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$geminiApiKey";

  @override
  void initState() {
    super.initState();
    loadLatestScanAndGeneratePlan();
  }

  // -------- FETCH + GENERATE --------
  Future<void> loadLatestScanAndGeneratePlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          plan = "User not logged in.";
          isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          plan = "No scan data found.";
          isLoading = false;
        });
        return;
      }

      final data = snapshot.docs.first.data();

      acneType = data['detectedType'];
      skinType = data['skinType'] ?? "Normal"; // fallback

      await generatePlan();
    } catch (e) {
      setState(() {
        plan = "Error fetching scan: $e";
        isLoading = false;
      });
    }
  }

  // -------- GEMINI PLAN --------
  Future<void> generatePlan() async {
    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Act as a dermatologist. Create a personalized acne treatment plan.\n"
                  "Acne Type: $acneType\n"
                  "Skin Type: $skinType\n\n"
                  "Include:\n"
                  "- Morning routine\n"
                  "- Night routine\n"
                  "- Do & Don't tips\n\n"
                  "Keep it simple and under 120 words.",
            }
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final candidates = data["candidates"];
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]["content"]["parts"];
          if (parts != null && parts.isNotEmpty) {
            plan = parts[0]["text"];
          } else {
            plan = "No content returned.";
          }
        } else {
          plan = "No response from AI.";
        }
      } else {
        plan = "Failed (${response.statusCode})";
      }
    } catch (e) {
      plan = "Network error.";
    }

    setState(() {
      isLoading = false;
    });
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Treatment Plan"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Personalized Plan",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text("Acne: $acneType"),
                        Text("Skin: $skinType"),

                        const Divider(height: 25),

                        Text(plan ?? ""),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}