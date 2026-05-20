import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Privacy Policy & Terms of Use",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Section 1: Privacy Policy Header ---
            Text(
              "1. Privacy Policy",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent.shade700,
              ),
            ),
            const Divider(color: Colors.blueAccent),
            const SizedBox(height: 10),

            _buildSectionHeader("1.1 Data Collection"),
            _buildPolicyText(
              "We collect minimal data to provide and improve the service. This includes:",
            ),
            _buildListItem(
              "Usage Data: Information about how you use the app (e.g., feature usage, crash reports).",
            ),
            _buildListItem(
              "Acne Progress Logs: Data voluntarily entered by you, such as severity scores, log entries, and **any progress photos you choose to upload (highly sensitive)**.",
            ),
            _buildListItem(
              "Device Identifiers: Non-personal information such as device type and operating system version.",
            ),
            const SizedBox(height: 15),

            _buildSectionHeader("1.2 How We Use Your Data"),
            _buildPolicyText("Your data is used solely to:"),
            _buildListItem(
              "Provide and maintain the app’s functionality (e.g., displaying your progress charts).",
            ),
            _buildListItem(
              "Personalize your experience and offer relevant tips.",
            ),
            _buildListItem(
              "Analyze and improve the app's performance and stability.",
            ),
            _buildPolicyText(
              "**Your progress photos and personal log entries are stored securely and are NEVER shared externally or sold to third parties.**",
            ),
            const SizedBox(height: 15),

            _buildSectionHeader("1.3 Data Security"),
            _buildPolicyText(
              "We implement industry-standard security measures, including encryption, to protect your personal and sensitive health data from unauthorized access or disclosure.",
            ),
            const SizedBox(height: 30),

            // --- Section 2: Terms of Use Header ---
            Text(
              "2. Terms of Use",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const Divider(color: Colors.deepOrange),
            const SizedBox(height: 10),

            _buildSectionHeader("2.1 Acceptance of Terms"),
            _buildPolicyText(
              "By using this application, you agree to be bound by these Terms of Use and acknowledge the Medical Disclaimer.",
            ),
            const SizedBox(height: 15),

            _buildSectionHeader("2.2 Use of Service"),
            _buildPolicyText(
              "You agree to use the app responsibly and not to use it for any unlawful purpose. You are responsible for maintaining the confidentiality of your account information.",
            ),
            const SizedBox(height: 15),

            _buildSectionHeader("2.3 Intellectual Property"),
            _buildPolicyText(
              "All content, features, and functionality of the application (including the code, design, and graphics) are the exclusive property of the developers and are protected by copyright laws.",
            ),
            const SizedBox(height: 15),

            _buildSectionHeader("2.4 Changes to Terms"),
            _buildPolicyText(
              "We reserve the right to modify these Terms and the Privacy Policy at any time. Your continued use of the app following any changes constitutes your acceptance of the new terms.",
            ),

            const SizedBox(height: 40),
            Text(
              "Last Updated: November 2025",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for sub-section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper widget for standard policy text
  Widget _buildPolicyText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }

  // Helper widget for bullet list items
  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("\u2022 ", style: TextStyle(fontSize: 16, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
