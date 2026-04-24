import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'core/ble/foreground_task_handler.dart';
import 'core/audio/audio_session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterForegroundTask.initCommunicationPort();
  initForegroundTask();
  await initAudioSession(); 

  runApp(
    const ProviderScope(
      child: DhritamApp(),
    ),
  );
}