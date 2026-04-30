import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

class ThisWeekState {
  final List<Session> weeklySessions;
  final String aiSummary;
  final double weeklyAvg;

  ThisWeekState({
    required this.weeklySessions,
    required this.aiSummary,
    required this.weeklyAvg,
  });
}

final thisWeekProvider = FutureProvider.autoDispose<ThisWeekState>((ref) async {
  final db = appDb; // Your global DB singleton
  final prefs = await SharedPreferences.getInstance();

  // 1. Get cached AI Summary from Phase 2
  final aiSummary = prefs.getString('ai_weekly_summary') ?? "Wear your Kavach X band for a few more days to generate your first weekly summary.";
  final weeklyAvg = prefs.getDouble('weekly_avg_rmssd') ?? 0.0;

  // 2. Fetch the last 7 days of sessions
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  
  final sessions = await (db.select(db.sessions)
        ..where((s) => s.startTime.isBiggerOrEqualValue(sevenDaysAgo))
        ..orderBy([(s) => OrderingTerm.asc(s.startTime)]))
      .get();

  return ThisWeekState(
    weeklySessions: sessions,
    aiSummary: aiSummary,
    weeklyAvg: weeklyAvg,
  );
});