import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import './scan_service.dart';
import '../ml/acne_tflite_classifier.dart';
import './image_crop_screen.dart';

class ScanSkinScreen extends StatefulWidget {
  const ScanSkinScreen({super.key});

  @override
  State<ScanSkinScreen> createState() => _ScanSkinScreenState();
}

class _ScanSkinScreenState extends State<ScanSkinScreen> {
  File? _image;
  String? _detectedType;
  double? _confidence;
  String? _recommendation;
  String? _error;
  bool _isLoading = false;
  bool _isRecLoading = false;

  String? _selectedSkinType;

  final ImagePicker _picker = ImagePicker();
  final AcneTFLiteClassifier _classifier = AcneTFLiteClassifier();

  // Silent offline fallback only — never shown as primary AI output
  static const Map<String, String> _fallbackTips = {
    'blackheads':
        "1. Use skincare products containing Salicylic Acid (BHA).\n2. Avoid heavy, oil-based products that can clog pores.\n3. Cleanse your skin twice daily with a gentle formula.",
    'cysts':
        "1. Apply cool compresses to help reduce pain and swelling.\n2. DO NOT pick or squeeze, as this can lead to scarring.\n3. Consult a dermatologist for professional treatment options.",
    'papules':
        "1. Use a gentle, non-foaming cleanser to avoid irritation.\n2. Keep your skin moisturized with lightweight, oil-free products.\n3. Avoid harsh physical scrubs or exfoliating tools.",
    'pustules':
        "1. Use targeted spot treatments containing Benzoyl Peroxide.\n2. Maintain a consistent and simple skincare routine.\n3. Avoid the temptation to pop or squeeze active pustules.",
    'whiteheads':
        "1. Look for non-comedogenic and oil-free labels on products.\n2. Use gentle chemical exfoliants like AHAs (Glycolic Acid).\n3. Ensure thorough cleansing after exercise or heavy sweating.",
  };

  @override
  void initState() {
    super.initState();
    _warmUpClassifier();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScanInfoDialog();
    });
  }

  Future<void> _warmUpClassifier() async {
    try {
      await _classifier.init();
    } catch (e) {
      debugPrint('ML INIT ERROR: $e');
    }
  }

  // ── Gemini ────────────────────────────────────────────────────────────────
  static const String _geminiApiKey = "AIzaSyBQWo16qnqE9nVZe6NOi16NgY959g_pyOk";
  static const String _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey";

  final List<String> skinTypes = [
    "Dry",
    "Oily",
    "Normal",
    "Combination",
    "Sensitive",
  ];

  Future<String?> _getGeminiRecommendation(
    String acneType,
    String skinType,
  ) async {
    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Act as a professional dermatology assistant. "
                  "Analyze: Acne Type ($acneType), Skin Type ($skinType). "
                  "Provide 3 professional, concise, and user-friendly tips. "
                  "No medical prescriptions. Keep response brief and actionable (max 60 words).",
            },
          ],
        },
      ],
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_ONLY_HIGH",
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_ONLY_HIGH",
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_ONLY_HIGH",
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_ONLY_HIGH",
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] as String?;
      } else {
        debugPrint("GEMINI ERROR: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("GEMINI NETWORK ERROR: $e");
      return null;
    }
  }

  // ── Image pick ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_selectedSkinType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your skin type first.")),
      );
      return;
    }

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);

    try {
      AcneTFLiteClassifier.validateImageFile(file);
    } on InvalidImageException catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        title: 'Invalid File',
        message: e.message,
        icon: Icons.broken_image_outlined,
      );
      return;
    }

    // Navigate to custom crop screen
    final croppedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => ImageCropScreen(imageFile: file)),
    );

    // User cancelled cropping
    if (croppedFile == null) return;

    setState(() {
      _image = croppedFile;
      _resetResult();
      _isLoading = true;
    });

    await _classifyWithTFLite(_image!);
  }

  void _showErrorDialog({
    required String title,
    required String message,
    IconData icon = Icons.error_outline,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, color: Colors.redAccent, size: 48),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetResult() {
    _detectedType = null;
    _confidence = null;
    _recommendation = null;
    _error = null;
  }

  String _mapAcneTypeToFirestore(String modelLabel) {
    final normalized = modelLabel.toLowerCase();
    if (normalized == 'cyst') return 'cysts';
    return normalized;
  }

  // ── TFLite classification ─────────────────────────────────────────────────
  Future<void> _classifyWithTFLite(File imageFile) async {
    try {
      final pred = await _classifier.predict(imageFile);

      if (pred.isNotInDataset) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showErrorDialog(
          title: 'Not In Our Dataset',
          message:
              'This skin condition does not exist in our dataset. '
              'Our model is trained to detect: '
              '${AcneTFLiteClassifier.classNames.join(", ")}.\n\n'
              'Please upload an image of affected skin with one of '
              'these conditions for an accurate analysis.',
          icon: Icons.info_outline,
        );
        return;
      }

      final detectedType = _mapAcneTypeToFirestore(pred.acneType);
      final confidence = pred.confidencePercent;

      if (confidence < 60.0) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showErrorDialog(
          title: 'Uncertain Prediction',
          message:
              'The confidence score is low (${confidence.toStringAsFixed(1)}%). '
              'This image may not contain acne or the skin is healthy.',
          icon: Icons.health_and_safety_outlined,
        );
        return;
      }

      // ── Show result card immediately with loading spinner for recommendation
      if (!mounted) return;
      setState(() {
        _detectedType = detectedType;
        _confidence = confidence;
        _recommendation = null; // Gemini will fill this — no hardcoded text
        _isLoading = false;
        _isRecLoading = true;
      });

      // ── Fetch Gemini recommendation
      final aiResult = await _getGeminiRecommendation(
        detectedType,
        _selectedSkinType!,
      );

      // ── Gemini first, silent fallback only if Gemini completely fails
      final finalRecommendation =
          aiResult ??
          _fallbackTips[detectedType] ??
          "Unable to generate a recommendation right now. Please check your connection and try again.";

      // ── Save to Firestore
      await ScanService.saveScanResult(
        detectedType: detectedType,
        confidence: confidence,
        recommendation: finalRecommendation,
        skinType: _selectedSkinType!,
      );

      if (!mounted) return;
      setState(() {
        _recommendation = finalRecommendation;
        _isRecLoading = false;
      });
    } on InvalidImageException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(
        title: 'Invalid Image',
        message: e.message,
        icon: Icons.broken_image_outlined,
      );
    } on NotSkinImageException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(
        title: 'Not a Skin Image',
        message: e.message,
        icon: Icons.image_not_supported_outlined,
      );
    } on HealthySkinException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(
        title: 'Healthy Skin Detected',
        message:
            'This skin appears healthy and clear. Our model is trained to detect '
            'acne types. Please upload an image of affected skin with visible '
            'blemishes for an accurate analysis.',
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      debugPrint("ML CLASSIFICATION ERROR: $e");
      if (!mounted) return;
      setState(() {
        _error = "Local detection failed: $e";
        _isLoading = false;
        _isRecLoading = false;
      });
    }
  }

  void _showScanInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.info_outline_rounded,
          color: Colors.blueAccent,
          size: 48,
        ),
        title: Text(
          "Before You Scan",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blueAccent,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our AI model is trained to detect the following acne types only:",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ...[
              ("🔵", "Blackheads"),
              ("⚪", "Whiteheads"),
              ("🔴", "Papules"),
              ("🟡", "Pustules"),
              ("🟠", "Cysts"),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(
                      item.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Results on normal or healthy skin may still show a prediction since the model is trained on these 5 acne types only.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                "Got it, Let's Scan!",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Scan Your Skin",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // ── Skin type selection ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Your Skin Type",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: skinTypes.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: _selectedSkinType == type,
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(
                          color: _selectedSkinType == type
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedSkinType = type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Image preview ────────────────────────────────────────────
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.blueGrey,
                    ),
            ),

            const SizedBox(height: 20),

            // ── Buttons ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: const Text("Camera"),
                  onPressed: _isLoading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                  onPressed: _isLoading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (_isLoading)
              const CircularProgressIndicator(color: Colors.blueAccent),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // ── Result card ──────────────────────────────────────────────
            if (!_isLoading && _detectedType != null)
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detected: ${_detectedType!.toUpperCase()}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Confidence: ${_confidence?.toStringAsFixed(1) ?? '--'}%",
                      ),
                      Text("Skin Type: $_selectedSkinType"),
                      const Divider(),
                      Row(
                        children: [
                          Text(
                            "AI Recommendation:",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isRecLoading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // ── Recommendation text or loading state ─────────
                      if (_isRecLoading)
                        Text(
                          "Generating personalized recommendation...",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          _recommendation ?? "No recommendation available.",
                          style: GoogleFonts.poppins(color: Colors.black),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
