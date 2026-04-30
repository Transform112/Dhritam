import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';
import '../providers/patterns_provider.dart';

class PatternsTab extends ConsumerWidget {
  const PatternsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(patternsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Circadian Rhythm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Your average recovery capacity mapped to the time of day.", style: TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
            const SizedBox(height: 16),
            
            // --- CUSTOM HEATMAP ---
            _buildHeatmapCard(state.hourlyAverages, isDark),

            const SizedBox(height: 32),

            const Text("Weekly Stress Flow", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("How your nervous system responds across the days of the week.", style: TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
            const SizedBox(height: 16),

            // --- DAY OF WEEK CHART ---
            _buildDayOfWeekChart(state.weekdayAverages, isDark),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        );
      },
    );
  }

  Widget _buildHeatmapCard(Map<int, double> hourlyAverages, bool isDark) {
    // Find the max value to dynamically scale the color opacity
    double maxRmssd = 1.0; 
    for (var value in hourlyAverages.values) {
      if (value > maxRmssd) maxRmssd = value;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          _buildHeatmapRow("Night", "12am", "5am", 0, hourlyAverages, maxRmssd),
          const SizedBox(height: 12),
          _buildHeatmapRow("Morning", "6am", "11am", 6, hourlyAverages, maxRmssd),
          const SizedBox(height: 12),
          _buildHeatmapRow("Afternoon", "12pm", "5pm", 12, hourlyAverages, maxRmssd),
          const SizedBox(height: 12),
          _buildHeatmapRow("Evening", "6pm", "11pm", 18, hourlyAverages, maxRmssd),
          
          const SizedBox(height: 24),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Stress", style: TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
              const SizedBox(width: 8),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.mutedGray.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 4),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.recoveryTeal.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 4),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.recoveryTeal, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              const Text("Recovery", style: TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeatmapRow(String label, String startL, String endL, int startHour, Map<int, double> data, double max) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text("$startL - $endL", style: const TextStyle(color: AppTheme.mutedGray, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              int hour = startHour + index;
              double val = data[hour] ?? 0.0;
              // Scale opacity from 0.1 (low recovery/high stress) to 1.0 (high recovery)
              double opacity = (val / max).clamp(0.1, 1.0);
              
              return Tooltip(
                message: "$hour:00 - ${val.toStringAsFixed(0)} ms",
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: val == 0 ? AppTheme.mutedGray.withValues(alpha: 0.1) : AppTheme.recoveryTeal.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfWeekChart(Map<int, double> data, bool isDark) {
    List<FlSpot> spots = [];
    for (int i = 1; i <= 7; i++) {
      spots.add(FlSpot(i.toDouble(), data[i] ?? 0.0));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.mutedGray.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 22, interval: 1,
                getTitlesWidget: (value, meta) {
                  const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value < 1 || value > 7) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt()], style: const TextStyle(color: AppTheme.mutedGray, fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0.5, maxX: 7.5, minY: 0, maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true, curveSmoothness: 0.4,
              color: AppTheme.primaryPurple, barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4, color: AppTheme.cardWhite, strokeWidth: 2, strokeColor: AppTheme.primaryPurple,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple.withValues(alpha: 0.3), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}