import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'core/ble/foreground_task_handler.dart';
import 'core/audio/audio_session_manager.dart';
import 'core/db/legacy_cleanup.dart';
import 'core/ai/model_service.dart'; // NEW: Import the Model Service
import 'core/notifications/notification_service.dart'; // NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await cleanUpLegacyCsvFiles();
  
  FlutterForegroundTask.initCommunicationPort();
  initForegroundTask();
  await initAudioSession();

  // NEW: Boot up the TFLite inference engine!
  await modelService.initModel();
  // NEW: Boot the notification engine
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: DhritamApp(),
    ),
  );
}