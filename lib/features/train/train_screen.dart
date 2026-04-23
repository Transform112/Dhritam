import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isActive = false;
  String _breathInstruction = "Ready";
  int _cyclesCompleted = 0;

  @override
  void initState() {
    super.initState();

    // The Master Timer: 10 seconds per full breath cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Asymmetric Breathing Animation: 4s Inhale, 6s Exhale
    _scaleAnimation = TweenSequence<double>([
      // INHALE: 4 seconds (40% of the timeline) - Expand from 1.0 to 2.2
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 2.2).chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 40.0,
      ),
      // EXHALE: 6 seconds (60% of the timeline) - Contract from 2.2 to 1.0
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    // Make the outer halo gently fade in and out with the breath
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 0.1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    // Listen to the animation clock to update the text UI
    _controller.addListener(() {
      setState(() {
        if (_controller.value < 0.4) {
          _breathInstruction = "Inhale";
        } else {
          _breathInstruction = "Exhale";
        }
      });
    });

    // Count cycles when the animation loops
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isActive) {
        setState(() {
          _cyclesCompleted++;
        });
        _controller.forward(from: 0.0); // Loop it
      }
    });
  }

  void _toggleSession() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _cyclesCompleted = 0;
        _controller.forward(from: 0.0);
      } else {
        _controller.stop();
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 800), curve: Curves.easeOut);
        _breathInstruction = "Ready";
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resonance Breathing', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header Text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              "Synchronize your breathing with the visualizer to maximize your Heart Rate Variability.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.mutedGray, height: 1.4),
            ),
          ),
          
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding Outer Halo
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.recoveryTeal.withValues(alpha: _opacityAnimation.value),
                          ),
                        ),
                      ),
                      
                      // Solid Inner Circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.recoveryTeal.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _breathInstruction,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _isActive ? AppTheme.recoveryTeal : AppTheme.mutedGray,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Bottom Controls & Stats
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                if (_isActive)
                  Text(
                    "Cycles Completed: $_cyclesCompleted",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.mutedGray),
                  ),
                const SizedBox(height: 16),
                
                // Big Start/Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isActive ? AppTheme.cardWhite : AppTheme.primaryPurple,
                      foregroundColor: _isActive ? AppTheme.stressRed : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _isActive ? AppTheme.stressRed.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: _toggleSession,
                    child: Text(
                      _isActive ? "End Session" : "Begin Exercise",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}