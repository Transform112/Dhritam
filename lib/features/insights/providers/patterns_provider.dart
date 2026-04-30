import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/app_database.dart';

class PatternsState {
  final Map<int, double> hourlyAverages;  // Hours 0 to 23
  final Map<int, double> weekdayAverages; // Days 1 (Mon) to 7 (Sun)

  PatternsState({
    required this.hourlyAverages,
    required this.weekdayAverages,
  });
}

final patternsProvider = FutureProvider.autoDispose<PatternsState>((ref) async {
  final db = appDb;
  
  // Fetch ALL historical windows to find macro patterns
  final windows = await db.select(db.hrvWindows).get();

  // Initialize accumulators
  Map<int, List<double>> hourGroups = {for (var i = 0; i < 24; i++) i: []};
  Map<int, List<double>> dayGroups = {for (var i = 1; i <= 7; i++) i: []};

  // Sort data into buckets
  for (var w in windows) {
    if (w.isReliable) {
      hourGroups[w.timestamp.hour]?.add(w.rmssd);
      dayGroups[w.timestamp.weekday]?.add(w.rmssd);
    }
  }

  // Calculate averages
  Map<int, double> hourlyAverages = {};
  Map<int, double> weekdayAverages = {};

  for (int i = 0; i < 24; i++) {
    if (hourGroups[i]!.isNotEmpty) {
      hourlyAverages[i] = hourGroups[i]!.reduce((a, b) => a + b) / hourGroups[i]!.length;
    } else {
      hourlyAverages[i] = 0.0;
    }
  }

  for (int i = 1; i <= 7; i++) {
    if (dayGroups[i]!.isNotEmpty) {
      weekdayAverages[i] = dayGroups[i]!.reduce((a, b) => a + b) / dayGroups[i]!.length;
    } else {
      weekdayAverages[i] = 0.0;
    }
  }

  return PatternsState(
    hourlyAverages: hourlyAverages,
    weekdayAverages: weekdayAverages,
  );
});