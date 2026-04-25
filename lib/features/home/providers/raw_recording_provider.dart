import 'package:flutter_riverpod/flutter_riverpod.dart';

class RawRecordingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRecording(bool isRecording) {
    state = isRecording;
  }
}

final rawRecordingProvider = NotifierProvider<RawRecordingNotifier, bool>(() {
  return RawRecordingNotifier();
});