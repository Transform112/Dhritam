import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../core/db/app_database.dart';
import 'providers/insights_provider.dart';

import 'tabs/this_week_tab.dart'; // NEW
import 'tabs/patterns_tab.dart'; // NEW
import 'tabs/reports_tab.dart'; // NEW

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch our SQLite providers for the "Today" tab
    final sessionsAsync = ref.watch(todaysSessionsProvider);
    final windowsAsync = ref.watch(todaysWindowsProvider);

    return DefaultTabController(
      length: 4, // We now have 4 tabs!
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppTheme.primaryPurple),
              tooltip: "Export ML Raw Data",
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                final sessionDir = Directory('${directory.path}/sessions');

                if (sessionDir.existsSync()) {
                  final files = sessionDir.listSync().whereType<File>().where((f) => f.path.endsWith('.csv')).toList();

                  if (files.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No raw data files found.")));
                    }
                    return;
                  }
                  List<XFile> xFiles = files.map((f) => XFile(f.path)).toList();
                  await SharePlus.instance.share(ShareParams(files: xFiles, text: "Kavach X Raw ECG Data"));
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          // NEW: The 4-Tab Navigation Bar
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryPurple,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.mutedGray,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: "Today"),
              Tab(text: "This Week"),
              Tab(text: "Patterns"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        
        // NEW: The Tab Contents
        body: TabBarView(
          children: [
            // TAB 1: TODAY (Your existing, fully functional code)
            _buildTodayTab(windowsAsync, sessionsAsync, isDark),
            
            // TAB 2: THIS WEEK (Placeholder)
            const ThisWeekTab(),
            
            // TAB 3: PATTERNS (Placeholder)
            const PatternsTab(),
            
            // TAB 4: REPORTS (Placeholder)
            const ReportsTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TODAY (Your Existing Logic)
  // ==========================================
  Widget _buildTodayTab(AsyncValue<List<HrvWindow>> windowsAsync, AsyncValue<List<Session>> sessionsAsync, bool isDark) {
    return windowsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error loading data: $err')),
      data: (windows) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildChartCard(windows, isDark),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text("Today's Sessions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            sessionsAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history_rounded, color: AppTheme.mutedGray),
                          SizedBox(width: 16),
                          Text("No sessions recorded yet today.", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildSessionCard(sessions[index], isDark);
                  }, childCount: sessions.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  // ==========================================
  // EXISTING UI COMPONENTS (Unchanged)
  // ==========================================
  Widget _buildChartCard(List<HrvWindow> windows, bool isDark) {
    List<FlSpot> spots = windows.isEmpty
        ? const [FlSpot(0, 0), FlSpot(24, 0)]
        : windows.map((w) {
            double timeX = w.timestamp.hour + (w.timestamp.minute / 60.0);
            return FlSpot(timeX, w.rmssd);
          }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("RMSSD Timeline", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.mutedGray.withValues(alpha: 0.2), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 22, interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value % 6 != 0) return const SizedBox.shrink();
                            int hour = value.toInt();
                            String label = hour == 0 || hour == 24 ? "12A" : hour == 12 ? "12P" : hour > 12 ? "${hour - 12}P" : "${hour}A";
                            return Text(label, style: const TextStyle(color: AppTheme.mutedGray, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: 24, minY: 0, maxY: 120,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots, isCurved: true, curveSmoothness: 0.35,
                        color: windows.isEmpty ? AppTheme.mutedGray.withValues(alpha: 0.2) : AppTheme.recoveryTeal,
                        barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: windows.isEmpty ? AppTheme.mutedGray.withValues(alpha: 0.05) : AppTheme.recoveryTeal.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                if (windows.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard.withValues(alpha: 0.8) : AppTheme.cardWhite.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timeline_rounded, color: AppTheme.mutedGray, size: 16),
                        SizedBox(width: 8),
                        Text("Awaiting today's data", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, bool isDark) {
    String startStr = "${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}";
    String endStr = session.endTime != null ? "${session.endTime!.hour.toString().padLeft(2, '0')}:${session.endTime!.minute.toString().padLeft(2, '0')}" : "Ongoing";
    String durationStr = session.endTime != null ? "${session.endTime!.difference(session.startTime).inMinutes} min" : "---";
    String avgRmssdStr = session.averageRmssd != null ? "${session.averageRmssd!.toStringAsFixed(0)} ms" : "Processing...";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primaryPurple, collapsedIconColor: AppTheme.mutedGray,
          title: Text("$startStr - $endStr", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text("Average RMSSD: $avgRmssdStr", style: const TextStyle(color: AppTheme.mutedGray, fontSize: 13)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn("Duration", durationStr),
                  _buildStatColumn("Signal Quality", session.signalQuality != null ? "${session.signalQuality!.toStringAsFixed(1)}%" : "--"),
                  _buildStatColumn("Status", session.endTime == null ? "Active" : "Saved"),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}