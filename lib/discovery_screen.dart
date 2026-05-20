import 'package:flutter/material.dart';
import './screens/product_recs_screen.dart';
import './screens/tips_myths_screen.dart';
import './screens/acne_types_screen.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          "Discovery Hub",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            _buildSearchBar(context),
            const SizedBox(height: 24),

            // Trending Topics
            _sectionTitle("Trending Topics"),
            const SizedBox(height: 10),
            _buildTopicChips(),
            const SizedBox(height: 24),

            // Explore by Category
            _sectionTitle("Explore by Category"),
            const SizedBox(height: 12),

            _buildDiscoveryCard(
              context,
              title: "Product Recommendations",
              subtitle: "Find curated cleansers, serums, and spot treatments.",
              icon: Icons.shopping_bag_outlined,
              screen: const ProductRecsScreen(),
            ),
            _buildDiscoveryCard(
              context,
              title: "Meet the Experts",
              subtitle:
                  "Connect with dermatologists and certified estheticians.",
              icon: Icons.contact_support_outlined,
              screen: FindDermatologistScreen(),
            ),
            _buildDiscoveryCard(
              context,
              title: "Acne Types Deep Dive",
              subtitle:
                  "Understand causes, symptoms, and specific care for each type.",
              icon: Icons.category_outlined,
              screen: const AcneTypesScreen(),
            ),
            _buildDiscoveryCard(
              context,
              title: "Tips & Myths Debunked",
              subtitle:
                  "Essential knowledge to clear up confusion (and your skin).",
              icon: Icons.lightbulb_outline,
              screen: const TipsMythsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: const InputDecoration(
          hintText: "Search ingredients, articles, or experts...",
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.blueAccent,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Search functionality initiated..."),
              backgroundColor: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicChips() {
    const topics = [
      "Salicylic Acid",
      "Hormonal Acne",
      "Niacinamide",
      "Acne Scars",
      "Retinoids",
      "Cystic Breakouts",
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topics.map((label) => _chip(label)).toList(),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF93C5FD), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildDiscoveryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade50,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.blueAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
