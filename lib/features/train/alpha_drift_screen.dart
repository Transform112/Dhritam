import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../core/ble/agna_connection_provider.dart';
import '../home/providers/rmssd_provider.dart';

import 'providers/bci_logger_provider.dart';

class AlphaDriftScreen extends ConsumerStatefulWidget {
  const AlphaDriftScreen({super.key});

  @override
  ConsumerState<AlphaDriftScreen> createState() => _AlphaDriftScreenState();
}

class _AlphaDriftScreenState extends ConsumerState<AlphaDriftScreen> {
  // Game limits
  final double _maxScore = 100.0;
  double _currentScore = 0.0;
  bool _isPlaying = false;
  
  // Track start time for the post-game summary
  DateTime? _sessionStartTime;

  void _toggleGame() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _currentScore = 0;
        _sessionStartTime = DateTime.now();
        // NEW: Start the dual-stream logger
        ref.read(bciLoggerProvider.notifier).startLogging();
      } else {
        // NEW: Stop the logger
        ref.read(bciLoggerProvider.notifier).stopLogging();
        _showPostGameSummary();
      }
    });
  }

  void _showPostGameSummary() {
    final duration = DateTime.now().difference(_sessionStartTime ?? DateTime.now());
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.cardWhite,
        title: const Text("Session Complete", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology_alt_rounded, size: 60, color: AppTheme.recoveryTeal),
            const SizedBox(height: 16),
            Text("Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s"),
            const SizedBox(height: 8),
            const Text("Your Kavach X HRV and Agna EEG data have been saved.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedGray)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close Dialog
              Navigator.of(context).pop(); // Exit Game Screen
            },
            child: const Text("Return to Training", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the dual data streams!
    final eegState = ref.watch(eegProvider);
    final rmssdState = ref.watch(rmssdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- GAME PHYSICS MATH ---
    // Calculate relative Alpha power (0.0 to 1.0)
    double totalPower = eegState.alpha + eegState.beta + eegState.theta;
    double alphaRatio = totalPower > 0 ? (eegState.alpha / totalPower) : 0.0;
    
    // Map ratio to vertical alignment (-1.0 is top, 1.0 is bottom)
    // We want high alpha (>0.5) to push the orb up.
    double verticalPosition = 1.0; 
    double orbScale = 1.0;
    Color orbColor = AppTheme.mutedGray;

    if (_isPlaying && eegState.isReliable) {
      // Inverse lerp: 0.8 ratio pushes to -0.8 alignment (top)
      verticalPosition = (1.0 - (alphaRatio * 2)).clamp(-0.8, 0.8);
      
      // Update score if Alpha is dominant
      if (alphaRatio > 0.4) {
         orbColor = AppTheme.recoveryTeal;
         orbScale = 1.2 + (alphaRatio * 0.5); // Pulse larger
         _currentScore = (_currentScore + (alphaRatio * 0.5)).clamp(0, _maxScore);
      } else {
         orbColor = AppTheme.moderateAmber;
         orbScale = 0.8; // Shrink
      }
    } else if (_isPlaying && !eegState.isReliable) {
      // Searching for signal
      verticalPosition = 0.0;
      orbColor = AppTheme.stressRed;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F5),
      body: Stack(
        children: [
          // 1. The Game Field & The Orb
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
            alignment: Alignment(0, verticalPosition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 100 * orbScale,
              height: 100 * orbScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orbColor.withValues(alpha: 0.8),
                    orbColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: orbColor.withValues(alpha: 0.4),
                    blurRadius: 40 * orbScale,
                    spreadRadius: 10 * orbScale,
                  )
                ],
              ),
              child: Center(
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),

          // 2. Target Zone Overlay
          IgnorePointer(
            child: Center(
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: AppTheme.recoveryTeal.withValues(alpha: 0.3), width: 2)),
                  color: AppTheme.recoveryTeal.withValues(alpha: 0.05),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Text("FLOW ZONE", style: TextStyle(color: AppTheme.recoveryTeal, fontWeight: FontWeight.bold, letterSpacing: 4)),
              ),
            ),
          ),

          // 3. Top HUD (Dual Device Status)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 32),
                    onPressed: () {
                      if (_isPlaying) {
                        _toggleGame();
                      } else {
                        // Safety measure just in case
                        ref.read(bciLoggerProvider.notifier).stopLogging();
                        Navigator.pop(context);
                      }
                    },
                  ),

                  // The Dual-Device Biometric HUD!
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.white70,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Agna EEG Readout
                        Row(
                          children: [
                            const Text("Agna Alpha", style: TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
                            const SizedBox(width: 8),
                            Icon(Icons.psychology_rounded, size: 16, color: eegState.isReliable ? AppTheme.primaryPurple : AppTheme.stressRed),
                            const SizedBox(width: 4),
                            Text("${(alphaRatio * 100).toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Kavach X HRV Readout
                        Row(
                          children: [
                            const Text("Kavach RMSSD", style: TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
                            const SizedBox(width: 8),
                            Icon(Icons.favorite_rounded, size: 16, color: rmssdState?.isReliable == true ? AppTheme.stressRed : AppTheme.mutedGray),
                            const SizedBox(width: 4),
                            // FIXED: Removed the unnecessary string interpolation "${...}"
                            Text(rmssdState?.isReliable == true ? rmssdState!.rmssd.toStringAsFixed(0) : "--", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // 4. Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0, left: 24, right: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _toggleGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.transparent : AppTheme.primaryPurple,
                    foregroundColor: _isPlaying ? AppTheme.stressRed : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: _isPlaying ? AppTheme.stressRed : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Text(
                    _isPlaying ? "End Session" : "Start Alpha Drift",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}