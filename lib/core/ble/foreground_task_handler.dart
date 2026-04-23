import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// The callback function must be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DhritamTaskHandler());
}

class DhritamTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // The service has started. Our BLE and Signal Isolates are already running 
    // independently, so we don't need to do heavy lifting here.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Optional: You could ping the BLE connection status here if needed.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Service killed by the OS or user.
  }
}

/// Initializes the foreground task configuration
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dhritam_recording_channel',
      channelName: 'Dhritam ECG Recording',
      channelDescription: 'Keeps the BLE connection to Kavach X alive in the background.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000), // Replaces interval & isOnceEvent
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}