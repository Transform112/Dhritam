import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/signal/signal_processor_isolate.dart';

final rmssdProvider = NotifierProvider<RmssdNotifier, RmssdResult?>(() {
  return RmssdNotifier();
});

class RmssdNotifier extends Notifier<RmssdResult?> {
  @override
  RmssdResult? build() => null;

  void updateState(RmssdResult? result) {
    state = result;
  }
}