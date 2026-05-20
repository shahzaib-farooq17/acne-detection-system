import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a scan result for the logged-in user.
  /// [confidence] is stored as a double (e.g. 87.3) — NOT a string.
  static Future<void> saveScanResult({
    required String detectedType,
    required double confidence, // ✅ double, not String
    required String recommendation,
    required String skinType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in — cannot save scan.');
    }

    await _firestore.collection('users').doc(user.uid).collection('scans').add({
      'timestamp': Timestamp.now(),
      'detectedType': detectedType,
      'confidence': confidence, // ✅ stored as number in Firestore
      'recommendation': recommendation,
      'skinType': skinType,
    });
  }

  /// Fetch scan history for the logged-in user.
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
