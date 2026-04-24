import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/app_database.dart';

// 1. Fetches all sessions recorded today
final todaysSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final allSessions = await appDb.getAllSessions();
  final now = DateTime.now();
  
  // Filter for today only
  return allSessions.where((s) =>
    s.startTime.year == now.year &&
    s.startTime.month == now.month &&
    s.startTime.day == now.day
  ).toList();
});

// 2. Fetches all individual 30-second data points from today's sessions
final todaysWindowsProvider = FutureProvider<List<HrvWindow>>((ref) async {
  final sessions = await ref.watch(todaysSessionsProvider.future);
  
  List<HrvWindow> todaysWindows = [];
  for (var session in sessions) {
    final windows = await appDb.getWindowsForSession(session.id);
    todaysWindows.addAll(windows);
  }
  
  // Ensure they are strictly chronological for the chart
  todaysWindows.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return todaysWindows;
});