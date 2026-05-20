import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Disclaimer & Credits",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            Colors.deepOrange, // Changed color for better distinction
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Section 1: Disclaimer ---
            Text(
              "Medical Disclaimer",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const Divider(color: Colors.deepOrangeAccent),
            const SizedBox(height: 10),
            Text(
              "This app is designed to assist in tracking and managing skin health. The information provided (including the Facts & Myths section) is for general informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider with any questions you may have regarding a medical condition.\n\nSpecific App Limitations:\n\u2022 This application does not offer personalized diagnostic tools.\n\u2022 Any recommendations provided are based on general skincare knowledge and should be vetted by a licensed dermatologist.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 30),

            // --- Section 2: Developer Credits ---
            Text(
              "Development Team",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const Divider(color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              "This application was developed with care and attention by:",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // Developer List
            _buildDeveloperCredit(
              "Shahzaib",
              "Project Lead, Flutter Development",
            ),
            _buildDeveloperCredit(
              "Shayan Humayun",
              "UI/UX Design, Content Curation",
            ),
            _buildDeveloperCredit(
              "Amir Riaz",
              "Backend Services & Data Integration",
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent developer credit display
  Widget _buildDeveloperCredit(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: " - $role",
                    style: TextStyle(color: Colors.grey.shade700),
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
