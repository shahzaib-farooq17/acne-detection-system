class ModelConfig {
  // Confidence thresholds - inspired by the Plant Disease logic mapped to Acne model
  static const double highConfidenceThreshold = 85.0; // percentage
  static const double mediumConfidenceThreshold = 70.0;
  static const double lowConfidenceThreshold = 50.0;
  static const double minimumPredictionThreshold = 40.0; 

  // Get confidence level description
  static String getConfidenceDescription(double confidence) {
    if (confidence >= highConfidenceThreshold) {
      return 'High Confidence';
    } else if (confidence >= mediumConfidenceThreshold) {
      return 'Medium Confidence';
    } else if (confidence >= lowConfidenceThreshold) {
      return 'Low Confidence';
    } else {
      return 'Very Low Confidence';
    }
  }
  
  // Get confidence color
  static int getConfidenceColor(double confidence) {
    if (confidence >= highConfidenceThreshold) {
      return 0xFF4CAF50; // Green
    } else if (confidence >= mediumConfidenceThreshold) {
      return 0xFFFF9800; // Orange
    } else if (confidence >= lowConfidenceThreshold) {
      return 0xFFFF5722; // Deep Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
