import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';

enum StressZone { recovered, moderate, stressed, unknown }

class ModelService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Initialize the TFLite Model
  Future<void> initModel() async {
    try {
      // Expects a model named 'dhritam_stress_model.tflite' in your assets folder
      // We wrap it in a try-catch so the app doesn't crash if you haven't trained it yet!
      _interpreter = await Interpreter.fromAsset('assets/dhritam_stress_model.tflite');
      _isInitialized = true;
      log("TFLite Model loaded successfully.");
    } catch (e) {
      log("TFLite Model not found. Falling back to heuristic rules temporarily: $e");
      _isInitialized = false;
    }
  }

  // The Inference Pipeline
  // The Inference Pipeline
  // NEW: Added baselineRmssd and isCalibrated parameters
  StressZone classifyState(double rmssd, int bpm, double baselineRmssd, bool isCalibrated) {
    
    // If we don't have 7 days of data, fallback to strict population ranges to be safe
    if (!isCalibrated || baselineRmssd == 0) {
      if (rmssd > 50) return StressZone.recovered;
      if (rmssd >= 30) return StressZone.moderate;
      return StressZone.stressed;
    }

    if (!_isInitialized || _interpreter == null) {
      // PERSONALIZED FALLBACK: Calculate zones based on the user's 30-day average!
      // Recovered = 15% above baseline. Stressed = 15% below baseline.
      final upperThreshold = baselineRmssd * 1.15;
      final lowerThreshold = baselineRmssd * 0.85;

      if (rmssd > upperThreshold) return StressZone.recovered;
      if (rmssd >= lowerThreshold) return StressZone.moderate;
      return StressZone.stressed;
    }

    // TFLite Inference Execution (Assuming model is trained on [RMSSD, BPM, BASELINE])
    var input = [[rmssd, bpm.toDouble(), baselineRmssd]]; // Feed baseline to ML!
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);
    
    try {
      _interpreter!.run(input, output);
      
      // Find the class with the highest probability
      List<double> probabilities = output[0];
      int maxIndex = 0;
      double maxProb = probabilities[0];
      
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Map output index to Zone (Assuming 0: Stressed, 1: Moderate, 2: Recovered)
      if (maxIndex == 0) return StressZone.stressed;
      if (maxIndex == 1) return StressZone.moderate;
      return StressZone.recovered;

    } catch (e) {
      log("Inference failed: $e");
      return StressZone.unknown;
    }
  }
}

// Global Singleton for easy access
final modelService = ModelService();