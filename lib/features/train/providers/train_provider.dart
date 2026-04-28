import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../home/providers/rmssd_provider.dart';

enum BreathingPhase { inhale, hold1, exhale, hold2, complete }

class BreathingPattern {
  final String name;
  final int inhale;
  final int hold1;
  final int exhale;
  final int hold2;

  const BreathingPattern(this.name, this.inhale, this.hold1, this.exhale, this.hold2);

  int get totalCycleTime => inhale + hold1 + exhale + hold2;
}

// Pre-defined Clinical Rhythms
const resonancePattern = BreathingPattern("Resonance (5.5s)", 5, 0, 5, 0);
const boxPattern = BreathingPattern("Box Breathing", 4, 4, 4, 4);
const relaxPattern = BreathingPattern("Deep Relax (4-7-8)", 4, 7, 8, 0);

class TrainSessionState {
  final bool isActive;
  final BreathingPattern selectedPattern;
  final BreathingPhase currentPhase;
  final int secondsRemainingInPhase;
  final int totalSessionSeconds;
  final double startingRmssd;
  final double currentRmssd;
  final bool isFinished;

  TrainSessionState({
    this.isActive = false,
    this.selectedPattern = resonancePattern,
    this.currentPhase = BreathingPhase.inhale,
    this.secondsRemainingInPhase = 5,
    this.totalSessionSeconds = 300, // 5 minutes default
    this.startingRmssd = 0.0,
    this.currentRmssd = 0.0,
    this.isFinished = false,
  });

  TrainSessionState copyWith({
    bool? isActive,
    BreathingPattern? selectedPattern,
    BreathingPhase? currentPhase,
    int? secondsRemainingInPhase,
    int? totalSessionSeconds,
    double? startingRmssd,
    double? currentRmssd,
    bool? isFinished,
  }) {
    return TrainSessionState(
      isActive: isActive ?? this.isActive,
      selectedPattern: selectedPattern ?? this.selectedPattern,
      currentPhase: currentPhase ?? this.currentPhase,
      secondsRemainingInPhase: secondsRemainingInPhase ?? this.secondsRemainingInPhase,
      totalSessionSeconds: totalSessionSeconds ?? this.totalSessionSeconds,
      startingRmssd: startingRmssd ?? this.startingRmssd,
      currentRmssd: currentRmssd ?? this.currentRmssd,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class TrainNotifier extends Notifier<TrainSessionState> {
  Timer? _ticker;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  TrainSessionState build() {
    // NEW: Modern Riverpod cleanup hook!
    ref.onDispose(() {
      _ticker?.cancel();
      _audioPlayer.dispose();
    });
    // Keep the current RMSSD updated in the state for the UI
    ref.listen(rmssdProvider, (prev, next) {
      if (next != null && next.isReliable) {
        state = state.copyWith(currentRmssd: next.rmssd);
      }
    });
    return TrainSessionState();
  }

  void setPattern(BreathingPattern pattern) {
    if (state.isActive) return;
    state = state.copyWith(
      selectedPattern: pattern,
      secondsRemainingInPhase: pattern.inhale,
      currentPhase: BreathingPhase.inhale,
    );
  }

  Future<void> startSession() async {
    // Lock in the baseline RMSSD for the Before/After comparison
    final currentData = ref.read(rmssdProvider);
    final baseline = currentData?.isReliable == true ? currentData!.rmssd : 0.0;

    state = state.copyWith(
      isActive: true, 
      isFinished: false,
      startingRmssd: baseline,
      totalSessionSeconds: 300, // Reset to 5 mins
      currentPhase: BreathingPhase.inhale,
      secondsRemainingInPhase: state.selectedPattern.inhale,
    );

    // TODO: Load Binaural Beat Audio (We will add an MP3 asset later!)
    await _audioPlayer.setAsset('assets/audio/binaural_432hz.mp3');
    _audioPlayer.setLoopMode(LoopMode.one);
    _audioPlayer.play();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    if (state.totalSessionSeconds <= 0) {
      endSession();
      return;
    }

    int phaseRemaining = state.secondsRemainingInPhase - 1;
    BreathingPhase nextPhase = state.currentPhase;

    if (phaseRemaining <= 0) {
      // Advance to the next phase in the cycle
      switch (state.currentPhase) {
        case BreathingPhase.inhale:
          nextPhase = state.selectedPattern.hold1 > 0 ? BreathingPhase.hold1 : BreathingPhase.exhale;
          phaseRemaining = nextPhase == BreathingPhase.hold1 ? state.selectedPattern.hold1 : state.selectedPattern.exhale;
          break;
        case BreathingPhase.hold1:
          nextPhase = BreathingPhase.exhale;
          phaseRemaining = state.selectedPattern.exhale;
          break;
        case BreathingPhase.exhale:
          nextPhase = state.selectedPattern.hold2 > 0 ? BreathingPhase.hold2 : BreathingPhase.inhale;
          phaseRemaining = nextPhase == BreathingPhase.hold2 ? state.selectedPattern.hold2 : state.selectedPattern.inhale;
          break;
        case BreathingPhase.hold2:
          nextPhase = BreathingPhase.inhale;
          phaseRemaining = state.selectedPattern.inhale;
          break;
        case BreathingPhase.complete:
          break;
      }
    }

    state = state.copyWith(
      totalSessionSeconds: state.totalSessionSeconds - 1,
      currentPhase: nextPhase,
      secondsRemainingInPhase: phaseRemaining,
    );
  }

  void endSession() {
    _ticker?.cancel();
    _audioPlayer.stop();
    state = state.copyWith(
      isActive: false, 
      isFinished: true,
      currentPhase: BreathingPhase.complete,
    );
  }

}

final trainProvider = NotifierProvider<TrainNotifier, TrainSessionState>(() {
  return TrainNotifier();
});