import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import 'providers/rmssd_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rmssdData = ref.watch(rmssdProvider);

    // Determine Zone and Colors (Rule-based fallback per PRD)
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
        title: const Text('Dhritam'),
        backgroundColor: AppTheme.bgOffWhite,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Primary Status Card
            Container(
              width: double.infinity,
              height: 180, // PRD Specification
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: zoneColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: zoneColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rmssdData == null || !rmssdData.isReliable 
                        ? "--" 
                        : rmssdData.rmssd.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 52, // Display font PRD spec
                      fontWeight: FontWeight.bold,
                      color: zoneColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    zoneLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rmssdData == null 
                        ? "Collecting 30 seconds of data..." 
                        : "Based on ${rmssdData.cleanRrCount} clean beats",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.mutedGray,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Placeholder for the AI Assistant Message Card (Week 4)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgOffWhite,
                borderRadius: BorderRadius.circular(16),
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
                      style: TextStyle(fontSize: 15, color: AppTheme.textDark),
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