/// Represents a single 2nd-Order Section (Biquad) using Transposed Direct Form II.
/// This structure guarantees floating-point stability for continuous real-time streams.
class BiquadSection {
  final double b0, b1, b2;
  final double a1, a2; // a0 is always normalized to 1.0 in SciPy

  // Internal state memory for the filter
  double _w1 = 0.0;
  double _w2 = 0.0;

  BiquadSection({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  /// Processes a single raw sample and updates the filter memory
  double process(double input) {
    double out = (b0 * input) + _w1;
    _w1 = (b1 * input) - (a1 * out) + _w2;
    _w2 = (b2 * input) - (a2 * out);
    return out;
  }

  /// Clears the filter memory (useful if the device disconnects and reconnects)
  void reset() {
    _w1 = 0.0;
    _w2 = 0.0;
  }
}

/// Chains multiple BiquadSections together. 
/// The output of Section 1 feeds directly into Section 2, and so on.
class BiquadCascade {
  final List<BiquadSection> _sections;

  BiquadCascade(this._sections);

  double process(double input) {
    double currentSignal = input;
    for (var section in _sections) {
      currentSignal = section.process(currentSignal);
    }
    return currentSignal;
  }

  void reset() {
    for (var section in _sections) {
      section.reset();
    }
  }
}

/// A factory class to generate our specific medical-grade filters for Kavach X
class KavachFilters {
  
  /// 50Hz Notch Filter (Sample Rate: 500Hz, Q-Factor: 30)
  /// Removes AC powerline noise without distorting the ECG waveform.
  static BiquadCascade create50HzNotch() {
    return BiquadCascade([
      BiquadSection(
        b0: 0.99375595, b1: -1.60790581, b2: 0.99375595,
        a1: -1.60790581, a2: 0.98751189,
      )
    ]);
  }

  /// 0.5Hz - 40Hz Bandpass Filter (Sample Rate: 500Hz, Butterworth Order 4)
  /// Removes baseline wander (breathing/motion) and high-frequency muscle noise.
  static BiquadCascade createEcgBandpass() {
    return BiquadCascade([
      // Section 1
      BiquadSection(
        b0: 0.04018264, b1: 0.08036528, b2: 0.04018264,
        a1: -1.02640277, a2: 0.35515228,
      ),
      // Section 2
      BiquadSection(
        b0: 1.0, b1: 2.0, b2: 1.0,
        a1: -1.22915226, a2: 0.60537446,
      ),
      // Section 3 (Highpass component to remove baseline wander)
      BiquadSection(
        b0: 1.0, b1: -2.0, b2: 1.0,
        a1: -1.98822602, a2: 0.98826065,
      ),
      // Section 4
      BiquadSection(
        b0: 1.0, b1: -2.0, b2: 1.0,
        a1: -1.99616896, a2: 0.9961726,
      )
    ]);
  }
}