import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import 'providers/train_provider.dart'; // Ensure this points to our new provider

class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainState = ref.watch(trainProvider);
    final trainNotifier = ref.read(trainProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathe', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: trainState.isFinished
          ? _buildPostSessionSummary(context, trainState, ref, isDark)
          : _buildActiveSession(context, trainState, trainNotifier, isDark),
    );
  }

  Widget _buildActiveSession(BuildContext context, TrainSessionState state, TrainNotifier notifier, bool isDark) {
    // 1. Determine Circle Target Size & Animation Duration based on Phase
    double circleSize = 180.0;
    Duration animDuration = const Duration(milliseconds: 500);
    String phaseText = state.selectedPattern.name;
    String timerText = "Ready";

    if (state.isActive) {
      timerText = "${state.secondsRemainingInPhase}";
      switch (state.currentPhase) {
        case BreathingPhase.inhale:
          circleSize = 320.0; // Expand
          animDuration = Duration(seconds: state.selectedPattern.inhale);
          phaseText = "Inhale";
          break;
        case BreathingPhase.hold1:
          circleSize = 320.0; // Stay Expanded
          animDuration = Duration(seconds: state.selectedPattern.hold1);
          phaseText = "Hold";
          break;
        case BreathingPhase.exhale:
          circleSize = 180.0; // Contract
          animDuration = Duration(seconds: state.selectedPattern.exhale);
          phaseText = "Exhale";
          break;
        case BreathingPhase.hold2:
          circleSize = 180.0; // Stay Contracted
          animDuration = Duration(seconds: state.selectedPattern.hold2);
          phaseText = "Hold";
          break;
        case BreathingPhase.complete:
          phaseText = "Done";
          break;
      }
    }

    return Column(
      children: [
        // --- PATTERN SELECTOR ---
        if (!state.isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPatternChip(resonancePattern, state.selectedPattern, notifier),
                  const SizedBox(width: 8),
                  _buildPatternChip(boxPattern, state.selectedPattern, notifier),
                  const SizedBox(width: 8),
                  _buildPatternChip(relaxPattern, state.selectedPattern, notifier),
                ],
              ),
            ),
          ),

        // --- MAIN BREATHING STAGE ---
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Outer Glow (Pulses slightly)
                if (state.isActive)
                  AnimatedContainer(
                    duration: animDuration,
                    curve: Curves.easeInOutSine,
                    width: circleSize + 40,
                    height: circleSize + 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.recoveryTeal.withValues(alpha: 0.1),
                    ),
                  ),

                // The Main Breathing Circle
                AnimatedContainer(
                  duration: animDuration,
                  curve: Curves.easeInOutSine, // Smooth, natural breathing curve
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.recoveryTeal.withValues(alpha: 0.8),
                        AppTheme.primaryPurple.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.recoveryTeal.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: state.currentPhase == BreathingPhase.inhale ? 10 : 0,
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          phaseText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (state.isActive) ...[
                          const SizedBox(height: 8),
                          Text(
                            timerText,
                            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300, height: 1.0),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- BOTTOM DASHBOARD ---
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            children: [
              // Live RMSSD Feedback
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headphones_rounded, color: AppTheme.mutedGray, size: 20),
                      SizedBox(width: 8),
                      Text("Binaural Beats", style: TextStyle(color: AppTheme.mutedGray, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppTheme.primaryPurple, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${state.currentRmssd.toStringAsFixed(0)} ms",
                          style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Start/Stop Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.isActive) {
                      notifier.endSession();
                    } else {
                      notifier.startSession();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isActive ? AppTheme.stressRed : AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    state.isActive ? "End Session" : "Start Session",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for the Pattern Chips
  Widget _buildPatternChip(BreathingPattern pattern, BreathingPattern selected, TrainNotifier notifier) {
    final isSelected = pattern.name == selected.name;
    return ChoiceChip(
      label: Text(pattern.name),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) notifier.setPattern(pattern);
      },
      selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryPurple : AppTheme.mutedGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primaryPurple : AppTheme.mutedGray.withValues(alpha: 0.3)),
      ),
    );
  }

  // --- POST SESSION SUMMARY (Before/After) ---
  Widget _buildPostSessionSummary(BuildContext context, TrainSessionState state, WidgetRef ref, bool isDark) {
    final delta = state.currentRmssd - state.startingRmssd;
    final percentChange = state.startingRmssd > 0 ? (delta / state.startingRmssd) * 100 : 0.0;
    final isPositive = delta >= 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: AppTheme.recoveryTeal),
            const SizedBox(height: 24),
            const Text("Session Complete", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("You completed the ${state.selectedPattern.name} routine.", style: const TextStyle(color: AppTheme.mutedGray)),
            
            const SizedBox(height: 40),
            
            // The Before/After Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text("HRV Impact", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("Before", state.startingRmssd),
                      const Icon(Icons.arrow_forward_rounded, color: AppTheme.mutedGray),
                      _buildStat("After", state.currentRmssd),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: isPositive ? AppTheme.recoveryTeal : AppTheme.moderateAmber,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppTheme.recoveryTeal : AppTheme.moderateAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPositive ? "Nervous system recovery improved." : "Baseline maintained.",
                    style: const TextStyle(color: AppTheme.mutedGray, fontSize: 14),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Magic Riverpod Trick: Invalidate the provider to completely reset it to default!
                  ref.invalidate(trainProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Done", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mutedGray, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          value > 0 ? value.toStringAsFixed(0) : "--",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text("ms", style: TextStyle(color: AppTheme.mutedGray, fontSize: 12)),
      ],
    );
  }
}