import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'rmssd_provider.dart';
import '../../../core/ai/model_service.dart';
import '../../../core/ai/offline_templates.dart';
import '../../../core/ai/api_client.dart'; 
import '../../profile/providers/baseline_provider.dart'; 
import '../../../core/notifications/notification_service.dart'; // Handles our background alerts

// Represents the data sent to the UI Card
class AiMessageState {
  final String message;
  final String actionLabel;
  final bool isAnalyzing;

  AiMessageState({required this.message, required this.actionLabel, this.isAnalyzing = false});
}

class AiAssistantNotifier extends Notifier<AiMessageState> {
  Timer? _zoneTimer;
  StressZone _currentZone = StressZone.unknown;
  DateTime? _lastApiCallTime;
  
  // NOTE: Set to 15 seconds for testing! Change to 15 * 60 for production (15 minutes)
  final int triggerSeconds = 15; 

  @override
  AiMessageState build() {
    // 1. Listen to the live RMSSD stream
    ref.listen(rmssdProvider, (previous, next) {
      if (next == null || !next.isReliable) return;

      // Grab the current baseline state
      final baselineState = ref.read(baselineProvider).value;
      final baseline = baselineState?.averageRmssd ?? 0.0;
      final isCalibrated = baselineState?.isCalibrated ?? false;

      // 2. Run TFLite Inference (Now with personal data!)
      final newZone = modelService.classifyState(next.rmssd, next.currentBpm, baseline, isCalibrated);

      // 3. Zone Change Detection
      if (newZone != _currentZone) {
        _currentZone = newZone;
        _startZoneTimer(newZone);
      }
    });

    return AiMessageState(
      message: "Connect your Kavach X device to begin analyzing your state.", 
      actionLabel: "Connect"
    );
  }

  void _startZoneTimer(StressZone zone) {
    _zoneTimer?.cancel();
    
    // If we just recovered, immediately praise the user!
    if (zone == StressZone.recovered) {
       state = AiMessageState(message: OfflineTemplates.getMessage(zone), actionLabel: "View Stats");
       return;
    }

    // Otherwise, start the 15-minute (or 15-second) countdown
    _zoneTimer = Timer(Duration(seconds: triggerSeconds), () {
      _triggerAiGeneration(zone);
    });
  }

  Future<void> _triggerAiGeneration(StressZone zone) async {
    state = AiMessageState(message: "Analyzing sustained biometrics...", actionLabel: "...", isAnalyzing: true);

    // Rate Limiting: 1 API call per 15 minutes
    final now = DateTime.now();
    bool canCallApi = _lastApiCallTime == null || now.difference(_lastApiCallTime!).inMinutes >= 15;

    // Grab the live biometrics to send to the Cloud
    final currentData = ref.read(rmssdProvider);

    if (canCallApi && currentData != null) {
      final cloudMessage = await AiApiClient.generateContextualInsight(
        currentData.rmssd, 
        currentData.currentBpm, 
        zone
      );

      // If the Cloud API succeeded, display the custom message!
      if (cloudMessage != null && cloudMessage.isNotEmpty) {
        _lastApiCallTime = now; // Reset the rate limit timer
        state = AiMessageState(
          message: cloudMessage, 
          actionLabel: zone == StressZone.stressed ? "Breathe" : "Log Note"
        );
        
        // NEW: Fire the OS Push Notification if Stressed!
        if (zone == StressZone.stressed) {
          NotificationService.showStressAlert(title: "Dhritam Alert", body: cloudMessage);
        }
        return; 
      }
    }
    
    // If rate-limited, offline, or the API fails, fall back to the local templates instantly
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate thinking
    
    final fallbackMessage = OfflineTemplates.getMessage(zone);
    state = AiMessageState(
      message: fallbackMessage, 
      actionLabel: zone == StressZone.stressed ? "Breathe" : "Log Note"
    );

    // NEW: Fire the OS Push Notification if Stressed! (Even if offline)
    if (zone == StressZone.stressed) {
      NotificationService.showStressAlert(title: "Dhritam Alert", body: fallbackMessage);
    }
  }
}

final aiAssistantProvider = NotifierProvider<AiAssistantNotifier, AiMessageState>(() {
  return AiAssistantNotifier();
});