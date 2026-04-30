class EegState {
  final double alpha; // Relaxation / Flow state
  final double beta;  // Active thinking / Focus
  final double theta; // Deep relaxation / Drowsiness
  final bool isReliable; // Based on signal quality/contact quality

  const EegState({
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.isReliable,
  });

  // Factory for an empty/disconnected state
  factory EegState.empty() => const EegState(alpha: 0, beta: 0, theta: 0, isReliable: false);

  // Helper to get the dominant frequency band
  String get dominantBand {
    if (!isReliable) return "Calibrating...";
    if (alpha > beta && alpha > theta) return "Alpha";
    if (beta > alpha && beta > theta) return "Beta";
    return "Theta";
  }
}