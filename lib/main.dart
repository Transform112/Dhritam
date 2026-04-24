import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'core/ble/foreground_task_handler.dart';
import 'core/audio/audio_session_manager.dart';
import 'core/db/legacy_cleanup.dart'; // NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Nuke the old CSV files to free up space!
  await cleanUpLegacyCsvFiles();
  
  FlutterForegroundTask.initCommunicationPort();
  initForegroundTask();
  await initAudioSession(); 

  runApp(
    const ProviderScope(
      child: DhritamApp(),
    ),
  );
}