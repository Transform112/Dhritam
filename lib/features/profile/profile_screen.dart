import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import 'providers/baseline_provider.dart'; 

import '../../core/db/app_database.dart';
import '../../core/db/mock_data_engine.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<File> _sessionFiles = [];
  bool _isLoadingFiles = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(baselineProvider.notifier).refreshBaseline();
    });
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingFiles = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sessionDir = Directory('${directory.path}/sessions');
      
      if (sessionDir.existsSync()) {
        final files = sessionDir.listSync().whereType<File>().where((f) => f.path.endsWith('.csv')).toList();
        // Sort newest first
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        setState(() => _sessionFiles = files);
      }
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _isLoadingFiles = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baselineAsync = ref.watch(baselineProvider); 
    final baselineState = baselineAsync.value;
    final isLoadingBaseline = baselineAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // THE DEVELOPER MAGIC BUTTON
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.moderateAmber),
            tooltip: "Inject 21 Days of Data",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Injecting 21 days of data... Please wait."))
              );
              
              await MockDataEngine.generateHistoricalData(appDb);
              
              // Force the UI to refresh with the new data
              await _loadSessions();
              await ref.read(baselineProvider.notifier).refreshBaseline();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Database populated successfully!"))
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryPurple,
        onRefresh: () async {
          await _loadSessions();
          await ref.read(baselineProvider.notifier).refreshBaseline();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // TOP HALF: WEEK 5 BASELINE & AI PATTERNS
              // ==========================================
              
              // 1. Permanent Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    child: const Text('HP', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Harshit Pachahara", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        baselineState?.isCalibrated == true ? "Calibrated • Active" : "Calibrating",
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600, 
                          color: baselineState?.isCalibrated == true ? AppTheme.recoveryTeal : AppTheme.moderateAmber
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // 2. Calibration Progress (Always visible if uncalibrated, even when loading)
              if (baselineState == null || !baselineState.isCalibrated) ...[
                _buildCalibrationCard(baselineState, isDark),
                const SizedBox(height: 24),
              ],

              // 3. Baseline Data
              const Text("Your Personal Baseline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBaselineCard(baselineState, isDark),
              
              const SizedBox(height: 24),
              
              // 4. AI Pattern Insights
              const Text("Pattern Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPatternCard(baselineState, isLoadingBaseline, isDark),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),

              // ==========================================
              // BOTTOM HALF: EXISTING ML EXPORT FILES
              // ==========================================
              const Text("Raw ML Exports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Manage your high-fidelity CSV datasets for model training.", style: TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
              const SizedBox(height: 16),

              if (_isLoadingFiles)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32), 
                    child: CircularProgressIndicator(color: AppTheme.primaryPurple)
                  )
                )
              else if (_sessionFiles.isEmpty)
                _buildEmptyState(isDark)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Scroll managed by outer SingleChildScrollView
                  itemCount: _sessionFiles.length,
                  itemBuilder: (context, index) {
                    final file = _sessionFiles[index];
                    return _buildAnimatedSessionCard(file, index, isDark);
                  },
                ),
                
              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- WEEK 5 BASELINE UI HELPERS ---

  Widget _buildCalibrationCard(BaselineState? state, bool isDark) {
    double progress = (state?.daysLogged ?? 0) / 7.0;
    int daysRemaining = state?.daysRemaining ?? 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.bgOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.moderateAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Calibration Phase", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("$daysRemaining days remaining", style: const TextStyle(color: AppTheme.moderateAmber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.mutedGray.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.moderateAmber),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const Text(
            "Wear Kavach X daily to establish your baseline. AI insights will become highly personalized once calibration is complete.",
            style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.mutedGray),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineCard(BaselineState? state, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Text(
            (state != null && state.averageRmssd > 0) ? state.averageRmssd.toStringAsFixed(0) : "--",
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: AppTheme.primaryPurple, height: 1.0),
          ),
          const SizedBox(height: 4),
          const Text("ms (30-day average)", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BaselineState? state, bool isLoading, bool isDark) {
    String patternText = "Keep wearing your device to generate pattern insights.";
    
    if (isLoading && state == null) {
      patternText = "Analyzing nervous system baseline...";
    } else if (state != null && state.isCalibrated) {
      if (state.averageRmssd > 45) {
        patternText = "Your parasympathetic system is highly active. You recover quickly from stressors.";
      } else if (state.averageRmssd > 25) {
        patternText = "You have a balanced nervous system with average recovery capability.";
      } else {
        patternText = "Your baseline indicates elevated chronic stress. Focus on deep rest protocols.";
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.bgOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(patternText, style: const TextStyle(fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }

  // --- ORIGINAL FILE UI HELPERS ---

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.mutedGray),
          SizedBox(height: 16),
          Text("No Raw Exports Yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            "Use the 'Log ML Data' button on the Home tab to capture datasets.", 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 14, color: AppTheme.mutedGray, height: 1.4)
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSessionCard(File file, int index, bool isDark) {
    final date = file.lastModifiedSync();
    final sizeStr = _formatFileSize(file.lengthSync());
    final dateStr = _formatDate(date);
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        final animationValue = (value - (delay / 1000)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(opacity: animationValue, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.insert_chart_rounded, color: AppTheme.primaryPurple, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(height: 6, width: 6, decoration: const BoxDecoration(color: AppTheme.recoveryTeal, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text("Raw ECG • $sizeStr", style: const TextStyle(fontSize: 13, color: AppTheme.mutedGray, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    color: AppTheme.primaryPurple,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(text: 'Dhritam Session Export: $dateStr', files: [XFile(file.path)]));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}