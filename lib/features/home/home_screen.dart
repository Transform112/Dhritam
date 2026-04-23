import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import 'providers/rmssd_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rmssdData = ref.watch(rmssdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Determine Zone and Colors based on RMSSD
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
      body: Padding(
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
                border: Border.all(
                  color: zoneColor.withValues(alpha: 0.3), 
                  width: 2
                ),
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
                  // Animated RMSSD Number
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0, 
                      end: (rmssdData != null && rmssdData.isReliable) ? rmssdData.rmssd : 0.0
                    ),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            rmssdData == null || !rmssdData.isReliable 
                                ? "--" 
                                : value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 72, 
                              fontWeight: FontWeight.w800,
                              color: zoneColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "ms",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: zoneColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Zone Label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      zoneLabel,
                      key: ValueKey<String>(zoneLabel),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Heart Rate & Quality Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BPM
                      const Icon(Icons.favorite, color: AppTheme.stressRed, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        rmssdData == null || !rmssdData.isReliable 
                            ? "-- BPM" 
                            : "${rmssdData.currentBpm} BPM",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedGray,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      Container(height: 16, width: 1, color: AppTheme.mutedGray.withValues(alpha: 0.3)),
                      const SizedBox(width: 16),
                      
                      // Data Quality
                      const Icon(Icons.analytics_outlined, color: AppTheme.primaryPurple, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        rmssdData == null 
                            ? "Collecting data..." 
                            : "${rmssdData.cleanRrCount} valid beats",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mutedGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
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