import 'dart:math';
import 'model_service.dart';

class OfflineTemplates {
  static final Random _random = Random();

  static String getMessage(StressZone zone) {
    final hour = DateTime.now().hour;
    String timeOfDay = "day";
    if (hour < 12) {
      timeOfDay = "morning";
    } else if (hour > 17) {
      timeOfDay = "evening";
    }
    List<String> pool = [];

    switch (zone) {
      case StressZone.stressed:
        if (timeOfDay == "morning") {
          pool = [
            "Your nervous system is running hot this morning. Take 2 minutes for deep breathing.",
            "High cognitive load detected early today. Consider delaying intense tasks.",
            "Morning stress is elevated. A quick walk could help reset your baseline."
          ];
        } else if (timeOfDay == "evening") {
          pool = [
            "You've been holding onto tension tonight. Let's do a resonance breathing exercise before bed.",
            "Evening stress remains high. Avoid screens for the next hour to help your HRV recover.",
            "Your body is struggling to wind down. Try a warm shower to activate your parasympathetic system."
          ];
        } else {
          pool = [
            "Sustained stress detected. It's time to step away from your workspace for a moment.",
            "Your RMSSD has dropped significantly. Your body needs a quick recovery break.",
            "I'm noticing a high stress pattern. Let's focus on extending your exhales."
          ];
        }
        break;

      case StressZone.moderate:
        pool = [
          "You're in a moderate state of arousal. Good for focus, but remember to take micro-breaks.",
          "Your system is balanced but leaning active. Stay hydrated.",
          "HRV is stable. You have the capacity for deep work right now."
        ];
        break;

      case StressZone.recovered:
        pool = [
          "Excellent recovery! Your nervous system is primed for peak performance today.",
          "Your HRV is looking incredibly strong. Great job managing your load.",
          "You are fully recovered. This is a perfect time for high-demand cognitive tasks."
        ];
        break;
        
      default:
        return "Connect your Kavach X device to begin analyzing your state.";
    }

    return pool[_random.nextInt(pool.length)];
  }
}