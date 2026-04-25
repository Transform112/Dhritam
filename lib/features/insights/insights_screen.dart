import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../core/db/app_database.dart';
import 'providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch our new SQLite providers
    final sessionsAsync = ref.watch(todaysSessionsProvider);
    final windowsAsync = ref.watch(todaysWindowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Insights',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: AppTheme.primaryPurple,
            ),
            tooltip: "Export ML Raw Data",
            onPressed: () async {
              // Fetch the folder where we save the CSVs
              final directory = await getApplicationDocumentsDirectory();
              final sessionDir = Directory('${directory.path}/sessions');

              if (sessionDir.existsSync()) {
                final files = sessionDir
                    .listSync()
                    .whereType<File>()
                    .where((f) => f.path.endsWith('.csv'))
                    .toList();

                if (files.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No raw data files found.")),
                    );
                  }
                  return;
                }

                // Convert dart:io Files to share_plus XFiles
                List<XFile> xFiles = files.map((f) => XFile(f.path)).toList();

                // Trigger the native iOS/Android share sheet
                await SharePlus.instance.share(
                  ShareParams(files: xFiles, text: "Kavach X Raw ECG Data"),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: windowsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPurple),
        ),
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
        data: (windows) {
          if (windows.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              // --- THE TIMELINE CHART ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildChartCard(windows, isDark),
                ),
              ),

              // --- SESSION LIST HEADER ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Today's Sessions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // --- EXPANDABLE SESSION CARDS ---
              sessionsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, s) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (sessions) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = sessions[index];
                      return _buildSessionCard(session, isDark);
                    }, childCount: sessions.length),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ), // Bottom padding
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 64, color: AppTheme.mutedGray),
          SizedBox(height: 16),
          Text(
            "No data recorded today.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedGray,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Wear Kavach X to generate your timeline.",
            style: TextStyle(color: AppTheme.mutedGray),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<HrvWindow> windows, bool isDark) {
    // Convert HRV Windows to chart data points
    // X-axis = Hours since midnight (e.g., 2:30 PM = 14.5)
    List<FlSpot> spots = windows.map((w) {
      double timeX = w.timestamp.hour + (w.timestamp.minute / 60.0);
      return FlSpot(timeX, w.rmssd);
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppTheme.textDark.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RMSSD Timeline",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.mutedGray.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        // Only show labels every 6 hours
                        if (value % 6 != 0) return const SizedBox.shrink();
                        int hour = value.toInt();
                        String label = hour == 0 || hour == 24
                            ? "12A"
                            : hour == 12
                            ? "12P"
                            : hour > 12
                            ? "${hour - 12}P"
                            : "${hour}A";
                        return Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.mutedGray,
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 24, // 24 hours in a day
                minY: 0,
                maxY: 120, // Max reasonable RMSSD
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.recoveryTeal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ), // Hide dots for a clean line
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.recoveryTeal.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, bool isDark) {
    // Format Time strings
    String startStr =
        "${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}";
    String endStr = session.endTime != null
        ? "${session.endTime!.hour.toString().padLeft(2, '0')}:${session.endTime!.minute.toString().padLeft(2, '0')}"
        : "Ongoing";

    // Calculate Duration
    String durationStr = "---";
    if (session.endTime != null) {
      int minutes = session.endTime!.difference(session.startTime).inMinutes;
      durationStr = "$minutes min";
    }

    // Format Average RMSSD
    String avgRmssdStr = session.averageRmssd != null
        ? "${session.averageRmssd!.toStringAsFixed(0)} ms"
        : "Processing...";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: Theme(
        // Hide the default ugly border on ExpansionTile
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primaryPurple,
          collapsedIconColor: AppTheme.mutedGray,
          title: Text(
            "$startStr - $endStr",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            "Average RMSSD: $avgRmssdStr",
            style: const TextStyle(color: AppTheme.mutedGray, fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn("Duration", durationStr),
                  _buildStatColumn(
                    "Signal Quality",
                    session.signalQuality != null
                        ? "${session.signalQuality!.toStringAsFixed(1)}%"
                        : "--",
                  ),
                  _buildStatColumn(
                    "Status",
                    session.endTime == null ? "Active" : "Saved",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.mutedGray),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
