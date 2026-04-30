import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../theme/app_theme.dart';
import '../services/pdf_report_service.dart';

// Provider to fetch CSV files
final csvFilesProvider = FutureProvider.autoDispose<List<File>>((ref) async {
  final directory = await getApplicationDocumentsDirectory();
  final sessionDir = Directory('${directory.path}/sessions');
  if (!sessionDir.existsSync()) return [];
  
  final files = sessionDir.listSync().whereType<File>().where((f) => f.path.endsWith('.csv')).toList();
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return files;
});

class ReportsTab extends ConsumerWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filesAsync = ref.watch(csvFilesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Clinical Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Generate printable PDF summaries of your AI analysis and biometrics.", style: TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
        const SizedBox(height: 16),

        // --- PDF GENERATION CARD ---
        InkWell(
          onTap: () => PdfReportService.viewWeeklyReport(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 40),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Weekly PDF Report", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("View, print, or share your 7-day summary", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        const Text("Raw CSV Datasets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Export high-fidelity raw data for external ML model training.", style: TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
        const SizedBox(height: 16),

        // --- CSV FILES LIST ---
        filesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
          error: (err, stack) => Center(child: Text("Error loading files: $err")),
          data: (files) {
            if (files.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
                ),
                child: const Center(child: Text("No CSV exports found.", style: TextStyle(color: AppTheme.mutedGray))),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final dateStr = "${file.lastModifiedSync().month}/${file.lastModifiedSync().day}/${file.lastModifiedSync().year}";
                final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.recoveryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.table_chart_rounded, color: AppTheme.recoveryTeal),
                    ),
                    title: Text("Raw ECG Data • $dateStr", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text("$sizeKb KB", style: const TextStyle(color: AppTheme.mutedGray, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.share_rounded, color: AppTheme.primaryPurple),
                      onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(file.path)])),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}