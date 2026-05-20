import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── MODEL ───────────────────────────────────────────────────────────────────

class ScanResult {
  final String id; // ✅ Added doc ID for deletion
  final String timestamp;
  final String detectedType;
  final double confidence;
  final String recommendation;
  final String skinType;

  ScanResult({
    required this.id,
    required this.timestamp,
    required this.detectedType,
    required this.confidence,
    required this.recommendation,
    required this.skinType,
  });

  factory ScanResult.fromFirestore(String docId, Map<String, dynamic> data) {
    return ScanResult(
      id: docId, // ✅ Store doc ID
      timestamp: (data['timestamp'] as Timestamp).toDate().toString().split(
        '.',
      )[0],
      detectedType: data['detectedType'] ?? 'Unknown',
      confidence: _parseConfidence(data['confidence']),
      recommendation: data['recommendation'] ?? 'No recommendation available.',
      skinType: data['skinType'] ?? '',
    );
  }

  static double _parseConfidence(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  bool get hasAcne => detectedType != 'No acne detected';
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  List<ScanResult> _history = [];
  bool _isLoading = true;
  String? _loadError;

  final User? _user = FirebaseAuth.instance.currentUser;

  static const Color kBlue = Colors.blueAccent;
  static const Color kBlueDark = Color(0xFF1E3A8A);
  static const Color kBlueTile = Color(0xFFDBEAFE);
  static const Color kPageBg = Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    if (_user == null) {
      setState(() {
        _loadError = 'No user logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('✅ Scans loaded: ${snapshot.docs.length}');

      setState(() {
        _history = snapshot.docs
            .map(
              (doc) => ScanResult.fromFirestore(doc.id, doc.data()),
            ) // ✅ Pass doc.id
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Scan load error: $e');
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  // ✅ Delete a single record from Firestore + local list
  Future<void> _deleteRecord(ScanResult result) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('scans')
          .doc(result.id)
          .delete();

      setState(() {
        _history.removeWhere((s) => s.id == result.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Record deleted.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete. Try again.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ Confirmation dialog before deletion
  Future<void> _confirmDelete(ScanResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Record',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: kBlueDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this scan record? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecord(result);
    }
  }

  List<TextSpan> _parseBold(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: FontWeight.w600, color: kBlueDark),
        ),
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Scan History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _loadError != null
          ? _errorState(_loadError!)
          : _history.isEmpty
          ? _emptyState()
          : _content(),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load scan history.\nCheck your internet connection.',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _loadError = null;
                });
                _loadScanHistory();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: kBlueTile,
              child: Icon(Icons.history_rounded, size: 40, color: kBlue),
            ),
            const SizedBox(height: 20),
            Text(
              'No scan history yet.\nScan your skin to start tracking!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blueGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final total = _history.length;
    final acneCount = _history.where((s) => s.hasAcne).length;
    final clearCount = total - acneCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard('Total scans', total.toString(), kBlue),
              const SizedBox(width: 8),
              _statCard(
                'Acne found',
                acneCount.toString(),
                const Color(0xFFC62828),
              ),
              const SizedBox(width: 8),
              _statCard(
                'Clear',
                clearCount.toString(),
                const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Recent scans'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            // ✅ Wrap each card in Dismissible for swipe-to-delete
            itemBuilder: (context, i) {
              final result = _history[i];
              return Dismissible(
                key: ValueKey(result.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Delete Record',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: kBlueDark,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to delete this scan record? This action cannot be undone.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: Colors.blueGrey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  return confirmed ?? false;
                },
                onDismissed: (_) => _deleteRecord(result),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                child: GestureDetector(
                  onLongPress: () =>
                      _confirmDelete(result), // ✅ Long-press fallback
                  child: _scanCard(result),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBlueTile, width: 0.8),
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
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kBlue,
        ),
      ),
    );
  }

  Widget _scanCard(ScanResult result) {
    final acne = result.hasAcne;
    final accentColor = acne
        ? const Color(0xFFEF5350)
        : const Color(0xFF43A047);
    final badgeBg = acne ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final badgeTextColor = acne
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);
    final baseStyle = GoogleFonts.poppins(
      fontSize: 12,
      color: const Color(0xFF475569),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBlueTile, width: 0.8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade50,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            result.timestamp,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              acne ? 'Acne detected' : 'Clear skin',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: kBlueTile, height: 1),
                      ),
                      _infoRow(
                        'Result',
                        result.detectedType,
                        acne
                            ? const Color(0xFFC62828)
                            : const Color(0xFF2E7D32),
                      ),
                      if (result.skinType.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _infoRow('Skin type', result.skinType, kBlueDark),
                      ],
                      if (acne) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(
                                'Confidence',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: result.confidence / 100,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        kBlue,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${result.confidence.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Recommended care',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kBlueDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: _parseBold(
                            result.recommendation,
                            baseStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
