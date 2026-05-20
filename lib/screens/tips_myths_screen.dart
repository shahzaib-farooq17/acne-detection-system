import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TipsMythsScreen extends StatelessWidget {
  const TipsMythsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Expanded Static Data List (25 items)
    final List<Map<String, String>> tipsMyths = [
      {
        "type": "Myth",
        "title": "Chocolate causes acne",
        "desc":
            "There’s no strong scientific evidence that chocolate directly causes acne. While a high-sugar, high-glycemic diet can affect skin, chocolate itself is rarely the main culprit.",
      },
      {
        "type": "Fact",
        "title": "Stress can worsen acne",
        "desc":
            "Stress hormones like cortisol may trigger oil glands (sebaceous glands) to produce more oil (sebum), which can significantly make acne worse, especially during periods of high anxiety.",
      },
      {
        "type": "Myth",
        "title": "Sun exposure cures acne",
        "desc":
            "The sun may temporarily dry pimples, but UV radiation damages skin cells, worsens inflammation, and can lead to more severe breakouts (known as 'acne flare-ups') in the long run. Always wear non-comedogenic sunscreen.",
      },
      {
        "type": "Fact",
        "title": "Over-washing irritates the skin",
        "desc":
            "Washing your face too often (more than twice daily) strips the skin's natural protective barrier, causing irritation, dryness, and sometimes a rebound effect where the skin produces even more oil. Twice a day is sufficient.",
      },
      {
        "type": "Myth",
        "title": "Only teenagers get acne",
        "desc":
            "Acne can affect adults of any age (adult acne), often due to hormonal fluctuations, diet, stress, or underlying health conditions. It is increasingly common in women in their 20s and 30s.",
      },
      {
        "type": "Fact",
        "title": "Diet and lifestyle matter",
        "desc":
            "A diet high in refined sugars, processed carbohydrates, and dairy products has been linked to acne flare-ups. Eating a balanced diet, staying hydrated, and getting enough sleep can help reduce inflammation.",
      },
      {
        "type": "Fact",
        "title": "Pillows need frequent cleaning",
        "desc":
            "Changing your pillowcase every 2-3 days is a simple but effective tip. Pillowcases accumulate oil, sweat, dead skin cells, and bacteria, which are transferred back to your face throughout the night, leading to clogged pores.",
      },
      {
        "type": "Myth",
        "title": "Popping pimples is helpful",
        "desc":
            "Attempting to pop a pimple almost always makes it worse. It pushes bacteria deeper into the pore, causes severe inflammation, increases the risk of infection, and often results in permanent scarring or post-inflammatory hyperpigmentation (dark spots).",
      },
      {
        "type": "Fact",
        "title": "Topical retinoids are highly effective",
        "desc":
            "Retinoids (like Tretinoin and Adapalene) are derivatives of Vitamin A and are one of the most effective treatments. They increase cell turnover, prevent pores from clogging, and reduce inflammation.",
      },
      {
        "type": "Myth",
        "title": "Makeup causes all breakouts",
        "desc":
            "While heavy, pore-clogging makeup (non-comedogenic products) can cause acne, many modern, oil-free formulations labeled 'non-comedogenic' or 'oil-free' are safe for acne-prone skin.",
      },
      {
        "type": "Fact",
        "title": "Salicylic Acid (BHA) is key for blackheads",
        "desc":
            "Salicylic Acid is a Beta-Hydroxy Acid (BHA) that is oil-soluble, meaning it can penetrate deep into the pores to dissolve the clogs that cause blackheads and whiteheads.",
      },
      {
        "type": "Myth",
        "title": "Acne is caused by poor hygiene",
        "desc":
            "Acne is primarily caused by hormonal factors, genetics, and excess oil production. While cleanliness helps, acne is not a sign of dirtiness, and excessive scrubbing will only damage the skin barrier.",
      },
      {
        "type": "Fact",
        "title": "Benzoyl Peroxide kills bacteria",
        "desc":
            "Benzoyl Peroxide is an effective topical treatment that releases oxygen into the pore, killing the *P. acnes* bacteria responsible for inflammatory acne (papules and pustules).",
      },
      {
        "type": "Myth",
        "title": "Toothpaste works as a spot treatment",
        "desc":
            "Toothpaste contains ingredients that dry out the skin, but it also often contains irritating chemicals (like fluoride, strong detergents, and flavoring agents) that can cause redness, peeling, and skin burns. Use a dedicated spot treatment instead.",
      },
      {
        "type": "Fact",
        "title": "Hormones are a primary cause",
        "desc":
            "Hormonal changes (especially during puberty, menstruation, pregnancy, or conditions like PCOS) cause a surge in androgens, leading to increased sebum production and acne development.",
      },
      {
        "type": "Fact",
        "title": "Cystic acne requires a dermatologist",
        "desc":
            "Cystic acne and nodules are deep, painful, inflammatory lesions that are highly likely to scar. They require prescription treatment, such as oral antibiotics or Isotretinoin, and cannot be treated effectively with over-the-counter products.",
      },
      {
        "type": "Myth",
        "title": "Tanning beds clear skin",
        "desc":
            "Absolutely false. Tanning beds cause significant UV damage, increase the risk of skin cancer, and can lead to premature aging. Any perceived improvement in acne is short-lived.",
      },
      {
        "type": "Fact",
        "title": "Certain medications can trigger acne",
        "desc":
            "Medications such as corticosteroids, certain epilepsy drugs, and lithium can cause acne or acne-like eruptions. Always consult your doctor if you suspect medication is causing breakouts.",
      },
      {
        "type": "Myth",
        "title": "Dry skin means you won't get acne",
        "desc":
            "Acne can occur on any skin type, including dry skin. Acne is caused by clogged pores, not just oil. Using harsh products that dry out the skin can actually make acne worse by damaging the skin barrier.",
      },
      {
        "type": "Fact",
        "title": "Non-comedogenic products are best",
        "desc":
            "Look for products labeled 'non-comedogenic,' meaning they are formulated specifically to not clog your pores. This applies to moisturizers, sunscreens, and makeup.",
      },
      {
        "type": "Myth",
        "title": "You should scrub hard to exfoliate",
        "desc":
            "Harsh physical scrubbing, especially with abrasive washes, should be avoided. This causes micro-tears and spreads bacteria. Gentle chemical exfoliation (AHAs/BHAs) is safer and more effective for acne.",
      },
      {
        "type": "Fact",
        "title": "Dirty phones are a problem",
        "desc":
            "Your cell phone screen harbors bacteria, oil, and makeup. When pressed against your face, it can cause breakouts, particularly along the jawline and cheeks (sometimes called 'acne mechanica'). Wipe your phone screen often.",
      },
      {
        "type": "Myth",
        "title": "Acne is contagious",
        "desc":
            "Acne is not contagious. It is an inflammatory condition related to hormones, oil, dead skin cells, and bacteria already present on the skin. You cannot catch acne from another person.",
      },
      {
        "type": "Fact",
        "title": "Gently moisturizing is necessary",
        "desc":
            "Even oily skin needs hydration. Moisturizing helps repair the skin barrier, which is often compromised by acne treatments (like retinoids or BP). Choose a lightweight, oil-free moisturizer.",
      },
      {
        "type": "Myth",
        "title": "Changing diet instantly cures acne",
        "desc":
            "While diet is important, changes take time. It takes weeks or months for skin cells to turn over and show visible improvement. Be patient and consistent with both diet changes and your topical routine.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Acne Facts & Myths",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent.shade100, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tipsMyths.length,
          itemBuilder: (context, index) {
            final item = tipsMyths[index];
            final isMyth = item["type"] == "Myth";
            final color = isMyth ? Colors.red.shade700 : Colors.green.shade700;
            final icon = isMyth
                ? Icons.cancel_outlined
                : Icons.check_circle_outline;
            final lightColor = isMyth
                ? Colors.red.shade50
                : Colors.green.shade50;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.5), width: 1),
                ),
                color: Colors.white,
                child: ExpansionTile(
                  // 3. ExpansionTile for better UI/UX and animation
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  iconColor: color,
                  collapsedIconColor: color,
                  backgroundColor: lightColor,
                  collapsedBackgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  // Title Widget
                  title: Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "${item["type"]}: ${item["title"]}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description (Hidden until expanded)
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: lightColor.withOpacity(0.8),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      width: double.infinity,
                      child: Text(
                        item["desc"]!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
