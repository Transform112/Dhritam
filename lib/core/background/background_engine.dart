import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';

// 1. The Top-Level Entry Point (MUST be top-level, not inside a class)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native Background Task Fired: $task");

    if (task == BackgroundEngine.nightlyInsightsTask) {
      try {
        await BackgroundEngine._generateNightlyInsights();
      } catch (e) {
        debugPrint("Background Task Failed: $e");
        return Future.value(false); // Tell OS to retry later
      }
    }
    return Future.value(true); // Success
  });
}

// 2. The Engine Controller
class BackgroundEngine {
  static const String nightlyInsightsTask = "com.dhritam.nightly_insights";

  // Initialize the native WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      // Removed the deprecated 'isInDebugMode' parameter!
    );
  }

  // Schedule the job to run every 24 hours (Ideally late at night)
  static Future<void> scheduleNightlyJob() async {
    await Workmanager().registerPeriodicTask(
      "nightly_insights_job_1",
      nightlyInsightsTask,
      frequency: const Duration(hours: 24),
      // Constraints ensure it only runs when it won't drain battery
      constraints: Constraints(
        networkType: NetworkType.connected, // Needed for the AI API call
        requiresBatteryNotLow: true,
      ),
    );
  }

  // --- THE ACTUAL BACKGROUND LOGIC ---
  static Future<void> _generateNightlyInsights() async {
    debugPrint("Background Isolate: Opening Database...");
    
    // We must instantiate a new DB connection because we are in a background isolate
    final db = AppDatabase(); 
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Fetch all sessions (In production, filter to last 7 days)
      final allSessions = await db.getAllSessions();
      
      if (allSessions.isEmpty) {
        await prefs.setString('ai_weekly_summary', "Wear your Kavach X band to generate your first weekly summary.");
        return;
      }

      // 2. Calculate Weekly Stats (Mocking 7-day avg for now)
      double totalRmssd = 0;
      int count = 0;
      
      // Look at up to the last 14 sessions (approx 7 days if 2 per day)
      final recentSessions = allSessions.take(14).toList();
      for (var s in recentSessions) {
        if (s.averageRmssd != null) {
          totalRmssd += s.averageRmssd!;
          count++;
        }
      }

      final weeklyAvg = count > 0 ? (totalRmssd / count) : 0.0;
      
      // 3. Generate the AI Summary (Layer 3 Context)
      // NOTE: In production, you will pass `weeklyAvg` to your Gemini API here.
      // For this step, we generate the string the AI *would* output based on the math.
      String aiSummary;
      if (weeklyAvg > 45.0) {
        aiSummary = "Your nervous system showed excellent recovery this week with an average RMSSD of ${weeklyAvg.toStringAsFixed(0)}ms. Your BCI Alpha Drift sessions correlate with higher evening parasympathetic tone. Keep up the current routine.";
      } else if (weeklyAvg > 25.0) {
        aiSummary = "Your weekly RMSSD averaged ${weeklyAvg.toStringAsFixed(0)}ms, indicating moderate systemic stress. You had a noticeable dip on Wednesday. Consider prioritizing 10 extra minutes of resonance breathing this weekend.";
      } else {
        aiSummary = "Warning: Your RMSSD dropped to a weekly average of ${weeklyAvg.toStringAsFixed(0)}ms. Your biometrics indicate high allostatic load. Prioritize sleep and active recovery immediately.";
      }

      // 4. Cache the result for the UI to read instantly in the morning
      await prefs.setString('ai_weekly_summary', aiSummary);
      await prefs.setDouble('weekly_avg_rmssd', weeklyAvg);
      
      debugPrint("Background Isolate: AI Summary Cached Successfully!");

    } finally {
      // Always close the DB connection in a background isolate to prevent locks
      await db.close(); 
    }
  }
}