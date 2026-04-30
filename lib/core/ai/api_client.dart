import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'model_service.dart';

class AiApiClient {
  // TODOs: Paste your actual Gemini API key here
  static const String _apiKey = "AIzaSyDTA0MxEETevJUDT-wGfIZRuZ_4uzj4Ztk"; 
  
  static Future<String?> generateContextualInsight(double rmssd, int bpm, StressZone zone) async {
    if (_apiKey == "YOUR_GEMINI_API_KEY" || _apiKey.isEmpty) {
      log("API Key missing. Defaulting to offline templates.");
      return null;
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

    // The Context Payload Builder
    final prompt = """
You are Dhritam, a clinical-grade but empathetic health AI companion. 
The user has been in a sustained '${zone.name}' state for over 15 minutes.
Current Biometrics:
- HRV (RMSSD): ${rmssd.toStringAsFixed(1)} ms
- Heart Rate: $bpm BPM

Write a concise, 2-sentence insight and recommendation for the user. 
Speak directly to them in the second person ("You"). 
Be scientific but warm. Do not use markdown, emojis, or hashtags.
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      log("Cloud AI Generation Failed: $e");
      return null; // Gracefully fall back to offline templates
    }
  }
}