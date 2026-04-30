import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';
import '../../../core/db/app_database.dart';
import '../providers/this_week_provider.dart';

class ThisWeekTab extends ConsumerWidget {
  const ThisWeekTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(thisWeekProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        // FIXED: Switched to ListView which cleanly supports padding and simple children
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- AI SUMMARY CARD ---
            _buildAiSummaryCard(state.aiSummary, isDark),
            
            const SizedBox(height: 24),
            
            // --- WEEKLY TREND STATS ---
            const Text("7-Day Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildWeeklyTrendCard(state.weeklyAvg, isDark),

            const SizedBox(height: 24),

            // --- WEEKLY BAR CHART ---
            _buildWeeklyBarChart(state.weeklySessions, isDark),
            
            const SizedBox(height: 100), // Bottom Padding
          ],
        );
      },
    );
  }

  Widget _buildAiSummaryCard(String summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.bgOffWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text("Weekly AI Review", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryPurple)),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard(double weeklyAvg, bool isDark) {
    // For the UI demonstration, we simulate a "+5% vs last week" 
    // In production, you'd compare this to the previous 7 days
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Average RMSSD", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(weeklyAvg.toStringAsFixed(0), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1.0)),
                  const SizedBox(width: 4),
                  const Text("ms", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.recoveryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppTheme.recoveryTeal, size: 20),
                SizedBox(width: 4),
                Text("+5%", style: TextStyle(color: AppTheme.recoveryTeal, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<Session> sessions, bool isDark) {
    // 1. Group sessions by Day of Week (1 = Mon, 7 = Sun)
    Map<int, List<double>> dailyRmssd = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: []};
    
    for (var s in sessions) {
      if (s.averageRmssd != null) {
        dailyRmssd[s.startTime.weekday]?.add(s.averageRmssd!);
      }
    }

    // 2. Create Bar Chart Groups
    List<BarChartGroupData> barGroups = [];
    for (int day = 1; day <= 7; day++) {
      double dayAvg = 0;
      if (dailyRmssd[day]!.isNotEmpty) {
        dayAvg = dailyRmssd[day]!.reduce((a, b) => a + b) / dailyRmssd[day]!.length;
      }

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: dayAvg,
              width: 16,
              color: dayAvg > 40 ? AppTheme.recoveryTeal : (dayAvg > 0 ? AppTheme.moderateAmber : AppTheme.mutedGray.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100, // Background bar height
                color: AppTheme.mutedGray.withValues(alpha: 0.1),
              ),
            ),
          ],
        )
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Recovery", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[value.toInt() - 1], style: const TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}