import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import 'app_database.dart'; // Ensure this points to your DB file

class MockDataEngine {
  static Future<void> generateHistoricalData(AppDatabase db) async {
    final random = math.Random();
    final now = DateTime.now();
    
    debugPrint("--- STARTING MOCK DATA INJECTION ---");
    
    // 1. Clear existing data for a clean slate
    await db.delete(db.hrvWindows).go();
    await db.delete(db.sessions).go();
    debugPrint("Old database cleared.");

    // 2. Inject 21 days of data
    for (int i = 21; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      
      // Morning Baseline (High HRV: ~65ms)
      await _injectSession(db, targetDate, hour: 8, durationMinutes: 10, baseRmssd: 65.0, random: random);
      
      // Afternoon Stress (Low HRV: ~30ms)
      await _injectSession(db, targetDate, hour: 14, durationMinutes: 20, baseRmssd: 30.0, random: random);
      
      // Evening Recovery (Moderate HRV: ~50ms)
      await _injectSession(db, targetDate, hour: 20, durationMinutes: 15, baseRmssd: 50.0, random: random);
    }
    
    debugPrint("--- MOCK DATA INJECTION COMPLETE! Generated 21 days of biometric history. ---");
  }

  static Future<void> _injectSession(
    AppDatabase db, 
    DateTime date, {
    required int hour, 
    required int durationMinutes, 
    required double baseRmssd, 
    required math.Random random
  }) async {
    // Generate a unique ID based on the date and hour
    final sessionId = 'mock_${date.year}${date.month}${date.day}_$hour';
    final startTime = DateTime(date.year, date.month, date.day, hour, 0);
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    
    double totalRmssd = 0;
    int pointCount = 0;
    
    // Generate data points every minute inside the session
    for (int m = 0; m < durationMinutes; m++) {
      final pointTime = startTime.add(Duration(minutes: m));
      
      // Add realistic noise (-10 to +10) to the baseline
      final noise = (random.nextDouble() * 20) - 10;
      final currentRmssd = (baseRmssd + noise).clamp(10.0, 120.0);
      
      // Inverse relationship: High RMSSD usually means lower resting BPM
      final currentBpm = (100 - (currentRmssd * 0.4)).toInt().clamp(50, 120);
      
      // Insert the Window
      await db.into(db.hrvWindows).insert(HrvWindowsCompanion.insert(
        sessionId: sessionId,
        timestamp: pointTime,
        rmssd: currentRmssd,
        bpm: currentBpm,
        isReliable: true,
      ));
      
      totalRmssd += currentRmssd;
      pointCount++;
    }
    
    final avgRmssd = totalRmssd / pointCount;
    
    // Insert the parent Session
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      id: sessionId,
      startTime: startTime,
      endTime: drift.Value(endTime),
      averageRmssd: drift.Value(avgRmssd),
      signalQuality: drift.Value(95.0 + random.nextDouble() * 5), // 95-100% reliability
    ));
  }
}