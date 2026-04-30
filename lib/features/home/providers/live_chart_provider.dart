import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'rmssd_provider.dart';

class LiveChartNotifier extends Notifier<List<FlSpot>> {
  int _xCounter = 0;
  // NEW: Define the maximum width of our sliding window
  static const int _maxDataPoints = 150; 

  @override
  List<FlSpot> build() {
    // Listen to the main RMSSD provider
    ref.listen(rmssdProvider, (previous, next) {
      if (next != null && next.isReliable) {
        
        final currentList = state.toList();
        currentList.add(FlSpot(_xCounter.toDouble(), next.rmssd));
        
        // NEW: The Sliding Window Logic
        // If we have more points than our max, drop the oldest one!
        if (currentList.length > _maxDataPoints) {
          currentList.removeAt(0);
        }

        _xCounter++;
        state = currentList;
        
      } else if (next == null) {
        // Device disconnected, clear the live chart
        _xCounter = 0;
        state = [];
      }
    });
    return [];
  }
}

final liveChartProvider = NotifierProvider<LiveChartNotifier, List<FlSpot>>(() {
  return LiveChartNotifier();
});