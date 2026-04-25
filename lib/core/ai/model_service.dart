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
  StressZone classifyState(double rmssd, int bpm) {
    if (!_isInitialized || _interpreter == null) {
      // FALLBACK: If your ML model isn't in the assets folder yet, use our math rules
      if (rmssd > 50) return StressZone.recovered;
      if (rmssd >= 30) return StressZone.moderate;
      return StressZone.stressed;
    }

    // TFLite Inference Execution
    // Assuming your model takes [RMSSD, BPM] and outputs an array of 3 probabilities
    var input = [[rmssd, bpm.toDouble()]];
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