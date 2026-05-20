import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────────────────────────
// PRODUCT RECOMMENDATIONS SCREEN
// ─────────────────────────────────────────────────────────────

class ProductRecsScreen extends StatelessWidget {
  const ProductRecsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          "Product Recommendations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          _sectionTitle("Non-inflammatory acne (clogs)"),
          const ProductCard(
            title: "Salicylic Acid Cleanser",
            imageUrl:
                "https://makeupstash.pk/cdn/shop/files/CeraVe_Acne_Control_Cleanser_2_Salicylic_Acid_237ml_Oil_Control_Acne_Treatment_Face_Wash.jpg?v=1777007864",
            description:
                "Helps unclog pores, remove blackheads and control oil.",
          ),
          const ProductCard(
            title: "Oil-Free Moisturizer",
            imageUrl:
                "https://skinshop.pk/cdn/shop/products/Dermive-Oil-Free.png?v=1761415816&width=713",
            description:
                "Lightweight hydration for acne-prone and sensitive skin.",
          ),
          _sectionTitle("Inflammatory acne (red bumps)"),
          const ProductCard(
            title: "Niacinamide Serum",
            imageUrl:
                "https://conaturalintl.com/cdn/shop/files/5_65acbbee-1693-4847-943e-0305fdae7595.jpg?v=1775018293",
            description:
                "Reduces redness, minimizes pores and improves skin tone.",
          ),
          const ProductCard(
            title: "Benzoyl Peroxide Gel",
            imageUrl:
                "https://glitzpharma.net/wp-content/uploads/2023/06/Benoxyl-Gel-5-768x432.jpg",
            description: "Targets acne-causing bacteria and active pimples.",
          ),
          _sectionTitle("Severe acne (cysts & nodules)"),
          const ProductCard(
            title: "Hydrocolloid Patches",
            imageUrl:
                "https://m.media-amazon.com/images/I/718FhMZfA+L._AC_SX644_CB1169409_QL70_.jpg",
            description:
                "Protects acne spots and helps absorb fluid overnight.",
          ),
          const ProductCard(
            title: "SPF 50 Sunscreen",
            imageUrl:
                "https://neopharskinsciences.com/cdn/shop/files/neobrellagel2copy.jpg?v=1774628943&width=1500",
            description:
                "Protects skin and prevents dark acne marks from worsening.",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.health_and_safety_outlined),
        label: const Text("Find Dermatologist"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FindDermatologistScreen()),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 55,
            height: 55,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 55,
              height: 55,
              color: const Color(0xFFDBEAFE),
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FIND DERMATOLOGIST SCREEN
// ─────────────────────────────────────────────────────────────

class FindDermatologistScreen extends StatefulWidget {
   const FindDermatologistScreen({super.key});

  @override
  State<FindDermatologistScreen> createState() =>
      _FindDermatologistScreenState();
}

class _FindDermatologistScreenState extends State<FindDermatologistScreen> {
  bool _isLocating = false;
  String _statusMessage = "Find dermatologists near your current location.";

  // ── Search using live GPS location ──────────────────────────
  Future<void> _searchWithLocation() async {
    setState(() {
      _isLocating = true;
      _statusMessage = "Getting your location...";
    });

    try {
      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
          _statusMessage = "Location permission denied.";
        });
        _showPermissionDialog();
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _statusMessage = "Location found! Opening Google Maps...";
      });

      await _openGoogleMapsWithCoords(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _statusMessage = "Could not get location. Try manual search.";
      });
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // ── Open Google Maps with real coordinates ───────────────────
  Future<void> _openGoogleMapsWithCoords(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/dermatologist/@$lat,$lng,14z",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ── Search by city name typed by user ────────────────────────
  Future<void> _searchByCity(String city) async {
    if (city.trim().isEmpty) return;
    final encoded = Uri.encodeComponent("dermatologist in $city");
    final Uri url = Uri.parse("https://www.google.com/maps/search/$encoded");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ── Fallback: generic search ──────────────────────────────────
  Future<void> _searchGeneric() async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/dermatologist+near+me",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Location Permission"),
        content: const Text(
          "Location access is required to find nearby dermatologists. "
          "Please enable it in your device settings or use the manual city search below.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showCitySearchSheet() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search by City",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Enter a city or area to find dermatologists there.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "e.g. Islamabad, Lahore, Karachi...",
                prefixIcon: const Icon(
                  Icons.location_city_rounded,
                  color: Colors.blueAccent,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _searchByCity(controller.text);
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text("Search on Google Maps"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          "Find a Dermatologist",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F8EF7), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Find Nearby\nDermatologists",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Option 1: Use my location ───────────────────────
            const Text(
              "Search Options",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),

            _OptionCard(
              icon: Icons.my_location_rounded,
              title: "Use My Current Location",
              subtitle:
                  "Automatically detect where you are and find the nearest dermatologists",
              color: Colors.blueAccent,
              isLoading: _isLocating,
              onTap: _isLocating ? null : _searchWithLocation,
            ),

            const SizedBox(height: 12),

            // ── Option 2: Search by city ────────────────────────
            _OptionCard(
              icon: Icons.location_city_rounded,
              title: "Search by City or Area",
              subtitle: "Type a city name to find dermatologists in that area",
              color: const Color(0xFF0891B2),
              onTap: _showCitySearchSheet,
            ),

            const SizedBox(height: 12),

            // ── Option 3: Generic search ────────────────────────
            _OptionCard(
              icon: Icons.search_rounded,
              title: "General Search",
              subtitle:
                  "Open Google Maps and search for dermatologists near me",
              color: const Color(0xFF7C3AED),
              onTap: _searchGeneric,
            ),

            const SizedBox(height: 28),

            // ── Tips ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Tips for Your Visit",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _tip("Take photos of your skin before the appointment"),
                  _tip("Note how long you've had the acne and any triggers"),
                  _tip("List any products or medications you currently use"),
                  _tip("Ask about both topical and oral treatment options"),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(color: Colors.blueAccent, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OPTION CARD WIDGET
// ─────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
