import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/app_database.dart';

class BaselineState {
  final double averageRmssd;
  final int daysLogged;
  final bool isCalibrated;
  final int daysRemaining;

  BaselineState({
    required this.averageRmssd,
    required this.daysLogged,
    required this.isCalibrated,
    required this.daysRemaining,
  });
}

class BaselineNotifier extends AsyncNotifier<BaselineState> {
  @override
  Future<BaselineState> build() async {
    return _calculateBaseline();
  }

  Future<BaselineState> _calculateBaseline() async {
    final allSessions = await appDb.getAllSessions();

    if (allSessions.isEmpty) {
      return BaselineState(averageRmssd: 0.0, daysLogged: 0, isCalibrated: false, daysRemaining: 7);
    }

    final uniqueDays = <String>{};
    double totalRmssd = 0;
    int validSessions = 0;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    for (var s in allSessions) {
      // 1. Count unique days (e.g., "2026-4-28")
      uniqueDays.add("${s.startTime.year}-${s.startTime.month}-${s.startTime.day}");

      // 2. Add to 30-day rolling average (if it's a valid session)
      if (s.averageRmssd != null && s.startTime.isAfter(thirtyDaysAgo)) {
        totalRmssd += s.averageRmssd!;
        validSessions++;
      }
    }

    final daysLogged = uniqueDays.length;
    final avgRmssd = validSessions > 0 ? (totalRmssd / validSessions) : 0.0;

    return BaselineState(
      averageRmssd: avgRmssd,
      daysLogged: daysLogged,
      isCalibrated: daysLogged >= 7,
      daysRemaining: daysLogged >= 7 ? 0 : 7 - daysLogged,
    );
  }

  // Call this when a new session ends to recalculate
  Future<void> refreshBaseline() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _calculateBaseline());
  }
}

final baselineProvider = AsyncNotifierProvider<BaselineNotifier, BaselineState>(() {
  return BaselineNotifier();
});