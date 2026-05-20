import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:acneapp/screens/profile_screen.dart';
import './screens/chatbot_chat.dart';
import './screens/acne_facts_screen.dart';
import './screens/acne_types_screen.dart';
import './screens/product_recs_screen.dart';
import './screens/routine_screen.dart';
import './screens/scan_skin_screen.dart';
import './screens/treatment_plan_screen.dart';
import './screens/weekly_report_screen.dart';
import './screens/article_screen.dart';
import './discovery_screen.dart';
import 'package:acneapp/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await NotificationService().requestPermissions();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeContent(),
      const DiscoveryScreen(),
      const ScanSkinScreen(),
      const ArticlesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_selectedIndex],
          if (_selectedIndex == 0)
            Positioned(
              bottom: 25,
              right: 25,
              child: FloatingActionButton(
                backgroundColor: Colors.blueAccent,
                elevation: 4,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AcneChatbotScreen()),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        iconSize: 28,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: "Find",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: "Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: "Articles",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("User not logged in"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String userName = "...";
        if (snapshot.hasData && snapshot.data!.exists) {
          userName = snapshot.data!.get('name') ?? "User";
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Acne Detection",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 19,
              ),
            ),
            backgroundColor: Colors.blueAccent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white24,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF0F4FF),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "✨ Hello, $userName!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 22),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickAction(
                      context,
                      Icons.shopping_bag_rounded,
                      "Products",
                      const ProductRecsScreen(),
                    ),
                    _quickAction(
                      context,
                      Icons.camera_alt_rounded,
                      "Scan",
                      const ScanSkinScreen(),
                    ),
                    _quickAction(
                      context,
                      Icons.bar_chart_rounded,
                      "Reports",
                      const WeeklyReportScreen(),
                    ),
                    _quickAction(
                      context,
                      Icons.access_time_rounded,
                      "Routine",
                      const RoutineScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Personalized Care
                _sectionTitle("Personalized Care"),
                Row(
                  children: [
                    _cardButton(
                      context,
                      "Treatment Plan",
                      Icons.medical_services_rounded,
                      const TreatmentPlanScreen(acneType: '', skinType: ''),
                    ),
                    _cardButton(
                      context,
                      "Routine",
                      Icons.access_time_rounded,
                      const RoutineScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Track & Report — single full-width card
                _sectionTitle("Track & Report"),
                _fullWidthCardButton(
                  context,
                  "Report",
                  Icons.bar_chart_rounded,
                  const WeeklyReportScreen(),
                ),
                const SizedBox(height: 22),

                // Learn More
                _sectionTitle("Learn More"),
                Row(
                  children: [
                    _cardButton(
                      context,
                      "Acne Types",
                      Icons.category_rounded,
                      const AcneTypesScreen(),
                    ),
                    _cardButton(
                      context,
                      "Acne Facts",
                      Icons.info_outline_rounded,
                      const AcneFactsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _cardButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Icon(icon, size: 24, color: Colors.blueAccent),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-width card for single items in a section
  Widget _fullWidthCardButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFDBEAFE),
              child: Icon(icon, size: 24, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}