import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'providers/raw_recording_provider.dart';
import '../../core/ble/kavach_connection_provider.dart';
import '../../shared/models/device_state.dart';

import '../../theme/app_theme.dart';
import 'providers/rmssd_provider.dart';
import 'providers/live_chart_provider.dart';
import 'providers/ai_assistant_provider.dart'; // NEW: Import the AI Provider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rmssdData = ref.watch(rmssdProvider);
    final liveChartData = ref.watch(liveChartProvider);
    final aiState = ref.watch(aiAssistantProvider); // NEW: Watch the AI state
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
      body: SingleChildScrollView(
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true, 
                        child: SizedBox(
                          width: math.max(MediaQuery.of(context).size.width - 64, liveChartData.length * 40.0),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 120, 
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false), 
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: liveChartData,
                                  isCurved: true,
                                  curveSmoothness: 0.3,
                                  color: zoneColor, 
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true), 
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
            // DHRITAM AI ASSISTANT (Replaced Placeholder)
            // ==========================================
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.bgOffWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: aiState.isAnalyzing 
                      ? AppTheme.primaryPurple.withValues(alpha: 0.5) 
                      : AppTheme.mutedGray.withValues(alpha: 0.1),
                  width: aiState.isAnalyzing ? 2 : 1,
                ),
                boxShadow: aiState.isAnalyzing 
                    ? [BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.1), blurRadius: 10)]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                        child: aiState.isAnalyzing
                            ? const SizedBox(
                                width: 16, height: 16, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple)
                              )
                            : const Text('D', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            aiState.message,
                            key: ValueKey<String>(aiState.message),
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (aiState.actionLabel != "Connect" && aiState.actionLabel != "...") ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Action: ${aiState.actionLabel}")));
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(aiState.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      // ==========================================
      // ML DATA LOGGING BUTTON
      // ==========================================
      floatingActionButton: ref.watch(kavachConnectionProvider) == DeviceConnectionState.connected
          ? FloatingActionButton.extended(
              onPressed: () {
                final isRecording = ref.read(rawRecordingProvider);
                if (isRecording) {
                  ref.read(kavachConnectionProvider.notifier).stopRawRecording();
                  ref.read(rawRecordingProvider.notifier).setRecording(false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ML Data Saved!")));
                } else {
                  ref.read(kavachConnectionProvider.notifier).startRawRecording();
                  ref.read(rawRecordingProvider.notifier).setRecording(true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recording Raw ML Data...")));
                }
              },
              backgroundColor: ref.watch(rawRecordingProvider) ? AppTheme.stressRed : AppTheme.primaryPurple,
              icon: Icon(
                ref.watch(rawRecordingProvider) ? Icons.stop_rounded : Icons.fiber_manual_record_rounded, 
                color: Colors.white
              ),
              label: Text(
                ref.watch(rawRecordingProvider) ? "Stop Logging" : "Log ML Data",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}