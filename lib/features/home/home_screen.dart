import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import 'providers/rmssd_provider.dart';
import 'providers/live_chart_provider.dart'; // NEW

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rmssdData = ref.watch(rmssdProvider);
    final liveChartData = ref.watch(liveChartProvider); // NEW
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color zoneColor = AppTheme.mutedGray;
    String zoneLabel = "Calibrating...";
    
    if (rmssdData != null && rmssdData.isReliable) {
      if (rmssdData.rmssd > 50) {
        zoneColor = AppTheme.recoveryTeal;
        zoneLabel = "Recovered";
      } else if (rmssdData.rmssd >= 30) {
        zoneColor = AppTheme.moderateAmber;
        zoneLabel = "Moderate stress";
      } else {
        zoneColor = AppTheme.stressRed;
        zoneLabel = "High stress";
      }
    } else if (rmssdData != null && !rmssdData.isReliable) {
      zoneColor = AppTheme.stressRed;
      zoneLabel = "Signal weak - Adjust device";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dhritam', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView( // Added scrollview to fit everything safely
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ==========================================
            // PRIMARY STATUS CARD (Animated)
            // ==========================================
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: zoneColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: zoneColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: (rmssdData != null && rmssdData.isReliable) ? rmssdData.rmssd : 0.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            rmssdData == null || !rmssdData.isReliable ? "--" : value.toStringAsFixed(0),
                            style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: zoneColor, height: 1.0),
                          ),
                          const SizedBox(width: 4),
                          Text("ms", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: zoneColor.withValues(alpha: 0.7))),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      zoneLabel,
                      key: ValueKey<String>(zoneLabel),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: AppTheme.stressRed, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        rmssdData == null || !rmssdData.isReliable ? "-- BPM" : "${rmssdData.currentBpm} BPM",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.mutedGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ==========================================
            // LIVE TIMELINE CHART (Horizontal Scroll)
            // ==========================================
            if (liveChartData.isNotEmpty) ...[
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Live Session Trend", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Expanded(
                      // The SingleChildScrollView enables the infinite horizontal scrolling
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true, // Auto-scrolls to the newest data on the right
                        child: SizedBox(
                          // Dynamically expand width based on data points, min 300px
                          width: math.max(MediaQuery.of(context).size.width - 64, liveChartData.length * 40.0),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 120, // Max reasonable RMSSD
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false), // Hide axes for a clean look
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: liveChartData,
                                  isCurved: true,
                                  curveSmoothness: 0.3,
                                  color: zoneColor, // Matches the current stress zone
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true), // Show dots so individual 30s windows are visible
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: zoneColor.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // ==========================================
            // AI ASSISTANT PLACEHOLDER (Week 4)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.bgOffWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    child: const Text('D', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Connect your Kavach X device to begin analyzing your state.",
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}