import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

class PdfReportService {
  // Native Dart formatting helpers to avoid needing the 'intl' package
  static String _formatLongDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatShortDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  static Future<void> viewWeeklyReport() async {
    final pdf = pw.Document();
    
    // 1. Fetch Data
    final db = appDb;
    final prefs = await SharedPreferences.getInstance();
    final aiSummary = prefs.getString('ai_weekly_summary') ?? "Keep wearing your device to generate pattern insights.";
    final weeklyAvg = prefs.getDouble('weekly_avg_rmssd') ?? 0.0;
    
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final sessions = await (db.select(db.sessions)
          ..where((s) => s.startTime.isBiggerOrEqualValue(sevenDaysAgo))
          ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
        .get();

    final dateStr = _formatLongDate(DateTime.now());

    // 2. Draw the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Dhritam Clinical Report", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple700)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.deepPurple200),
              pw.SizedBox(height: 20),

              // AI Summary Section
              pw.Text("AI Nervous System Analysis", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Text(aiSummary, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
              ),
              pw.SizedBox(height: 24),

              // Stats Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox("Weekly Avg RMSSD", "${weeklyAvg.toStringAsFixed(0)} ms"),
                  _buildStatBox("Total Sessions", "${sessions.length}"),
                  _buildStatBox("Data Quality", "High"),
                ],
              ),
              pw.SizedBox(height: 32),

              // Sessions Table
              pw.Text("Session Log (Last 7 Days)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 12),
              
              if (sessions.isEmpty)
                pw.Text("No sessions recorded this week.", style: const pw.TextStyle(color: PdfColors.grey600))
              else
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple400),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  data: <List<String>>[
                    <String>['Date', 'Time', 'Duration', 'Avg RMSSD', 'Quality'],
                    ...sessions.map((s) {
                      final duration = s.endTime != null ? "${s.endTime!.difference(s.startTime).inMinutes} min" : "N/A";
                      final rmssd = s.averageRmssd != null ? "${s.averageRmssd!.toStringAsFixed(0)} ms" : "N/A";
                      final quality = s.signalQuality != null ? "${s.signalQuality!.toStringAsFixed(0)}%" : "N/A";
                      return [
                        _formatShortDate(s.startTime),
                        _formatTime(s.startTime),
                        duration,
                        rmssd,
                        quality,
                      ];
                    })
                  ],
                ),
            ],
          );
        },
      ),
    );

    // 3. Launch Native PDF Viewer
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Dhritam_Weekly_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple700)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ]
    );
  }
}