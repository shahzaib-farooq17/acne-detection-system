import 'package:flutter/material.dart';

// ── Data Model ────────────────────────────────────────────────────────────────

class AcneType {
  final String name;
  final String description;
  final String category;
  final String emoji;

  const AcneType({
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AcneTypesScreen extends StatelessWidget {
  const AcneTypesScreen({super.key});

  static const List<AcneType> _acneTypes = [
    AcneType(
      name: "Blackheads (Open Comedones)",
      description:
          "Pores clogged with sebum and dead skin cells that remain open to air. The black color comes from oxidation of trapped melanin and oil — not dirt.",
      category: "Non-Inflammatory",
      emoji: "⚫",
    ),
    AcneType(
      name: "Whiteheads (Closed Comedones)",
      description:
          "Pores clogged with oil and dead skin cells covered by a thin layer of skin. They appear as small white or flesh-colored bumps.",
      category: "Non-Inflammatory",
      emoji: "⚪",
    ),
    AcneType(
      name: "Papules",
      description:
          "Small, solid, raised bumps that are red and tender. They form when the follicle wall breaks due to severe inflammation. No visible pus.",
      category: "Inflammatory",
      emoji: "🔴",
    ),
    AcneType(
      name: "Pustules",
      description:
          "Papules that have developed a visible white or yellowish center of pus, surrounded by a red ring. Painful but generally easy to treat topically.",
      category: "Inflammatory",
      emoji: "💥",
    ),
    AcneType(
      name: "Cystic Acne",
      description:
          "The most severe form. Deep, painful, pus-filled cysts felt below the skin. Highly prone to scarring and always require dermatological intervention.",
      category: "Severe Inflammatory",
      emoji: "🩸",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final nonInflammatory = _acneTypes
        .where((t) => t.category == "Non-Inflammatory")
        .toList();
    final inflammatory = _acneTypes
        .where((t) => t.category == "Inflammatory")
        .toList();
    final severe = _acneTypes
        .where((t) => t.category == "Severe Inflammatory")
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          "Acne Types Guide",
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Non-Inflammatory (Mild)"),
            const SizedBox(height: 10),
            ...nonInflammatory.map((t) => _AcneTile(type: t)),

            const SizedBox(height: 20),
            _sectionTitle("Inflammatory (Moderate)"),
            const SizedBox(height: 10),
            ...inflammatory.map((t) => _AcneTile(type: t)),

            const SizedBox(height: 20),
            _sectionTitle("Severe Inflammatory (See a dermatologist)"),
            const SizedBox(height: 10),
            ...severe.map((t) => _AcneTile(type: t)),
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
}

// ── Expansion Tile Card ───────────────────────────────────────────────────────

class _AcneTile extends StatefulWidget {
  final AcneType type;
  const _AcneTile({required this.type});

  @override
  State<_AcneTile> createState() => _AcneTileState();
}

class _AcneTileState extends State<_AcneTile> {
  // ignore: unused_field
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (val) => setState(() => _expanded = val),
            backgroundColor: const Color(0xFFF0F4FF),
            collapsedBackgroundColor: Colors.white,
            iconColor: Colors.blueAccent,
            collapsedIconColor: const Color(0xFF93C5FD),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.type.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.type.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                color: const Color(0xFFF0F4FF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.type.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
