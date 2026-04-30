import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart'; // NEW: Required for debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/ble/agna_connection_provider.dart';
import '../../home/providers/rmssd_provider.dart';

class BciLoggerNotifier extends Notifier<bool> {
  Timer? _logTimer;
  File? _currentFile;
  IOSink? _sink;
  DateTime? _sessionStartTime;

  @override
  bool build() {
    ref.onDispose(() {
      _stopLogging();
    });
    return false; // isLogging = false
  }

  Future<void> startLogging() async {
    if (state) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final sessionDir = Directory('${directory.path}/bci_sessions');
      if (!await sessionDir.exists()) {
        await sessionDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      _currentFile = File('${sessionDir.path}/alpha_drift_$timestamp.csv');
      _sink = _currentFile!.openWrite();
      
      // Write CSV Header
      _sink!.writeln('Timestamp,Relative_Time_Sec,Alpha,Beta,Theta,RMSSD');
      
      _sessionStartTime = DateTime.now();
      
      // Log data every 1 second
      _logTimer = Timer.periodic(const Duration(seconds: 1), (_) => _logDataPoint());
      
      state = true;
    } catch (e) {
      // FIXED: Using debugPrint instead of print
      debugPrint("Error starting BCI logger: $e");
      state = false;
    }
  }

  void _logDataPoint() {
    if (_sink == null || _sessionStartTime == null) return;

    // Grab the current state of BOTH devices
    final eeg = ref.read(eegProvider);
    final rmssd = ref.read(rmssdProvider);

    final secondsElapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
    final timestamp = DateTime.now().toIso8601String();
    
    final rmssdValue = (rmssd != null && rmssd.isReliable) ? rmssd.rmssd.toStringAsFixed(2) : "";

    _sink!.writeln('$timestamp,$secondsElapsed,${eeg.alpha},${eeg.beta},${eeg.theta},$rmssdValue');
  }

  Future<void> stopLogging() async {
    if (!state) return;
    await _stopLogging();
    state = false;
  }

  Future<void> _stopLogging() async {
    _logTimer?.cancel();
    _logTimer = null;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}

final bciLoggerProvider = NotifierProvider<BciLoggerNotifier, bool>(() {
  return BciLoggerNotifier();
});