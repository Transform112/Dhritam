import 'dart:isolate';
import 'dart:math';

/// Payload to initialize the Signal Processor Isolate
class SignalIsolateInit {
  final SendPort mainStateSendPort;

  SignalIsolateInit({required this.mainStateSendPort});
}

/// The result payload sent back to the main thread every 30 seconds
class RmssdResult {
  final double rmssd;
  final double sd1;
  final double sd2;
  final int cleanRrCount;
  final bool isReliable;

  RmssdResult({
    required this.rmssd,
    required this.sd1,
    required this.sd2,
    required this.cleanRrCount,
    required this.isReliable,
  });
}

class SignalProcessorIsolate {
  static Isolate? _isolate;
  static SendPort? _signalSendPort;

  /// Starts the isolate and returns the SendPort for the BleProcessor to use
  static Future<SendPort> spawn(SignalIsolateInit initData) async {
    final receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _isolateEntry,
      [receivePort.sendPort, initData],
      debugName: 'SignalProcessorIsolate',
    );

    _signalSendPort = await receivePort.first as SendPort;
    return _signalSendPort!;
  }

  static void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _signalSendPort = null;
  }

  // ===========================================================================
  // ISOLATE ENTRY POINT - ALL HEAVY MATH RUNS HERE
  // ===========================================================================

  static void _isolateEntry(List<dynamic> args) {
    final SendPort handshakePort = args[0];
    final SignalIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    handshakePort.send(receivePort.sendPort);

    // --- State for 30-second window (15,000 samples @ 500Hz) ---
    int samplesInCurrentWindow = 0;
    List<double> currentWindowRrIntervals = [];
    
    // --- Pan-Tompkins State ---
    // Moving window for integration (150ms = 75 samples at 500Hz)
    final int mwLength = 75;
    List<double> mwBuffer = List.filled(mwLength, 0.0);
    int mwIndex = 0;
    
    // Peak detection state
    double adaptiveThreshold = 0.0;
    List<double> recentPeaks = [];
    int samplesSinceLastPeak = 0;
    final int refractoryPeriod = 100; // 200ms at 500Hz (cannot have 2 beats this close)

    // Filter state (Previous inputs/outputs for IIR biquads)
    // Note: In production, insert your exact pre-computed SciPy coefficients here.
    // FIX: Removed unused y2 variable
    double x1 = 0, x2 = 0;

    receivePort.listen((message) {
      if (message is! List<int>) return; // Expecting batches of 150 ints
      
      final List<int> rawBatch = message;

      for (int i = 0; i < rawBatch.length; i++) {
        samplesInCurrentWindow++;
        samplesSinceLastPeak++;

        // 1. Convert to mV (Optional, assuming 3.3V, 12-bit ADC centered at 1.65V)
        double signal = (rawBatch[i] / 4095.0) * 3300.0 - 1650.0;

        // 2. Apply Filters (Conceptual Biquad Application)
        // Apply 0.5-40Hz Bandpass and 50Hz Notch. 
        // using simple placeholder biquad math for structural completeness:
        double filtered = signal; // filtered = b0*signal + b1*x1 + b2*x2 - a1*y1 - a2*y2...
        
        // Update filter state
        x2 = x1; x1 = signal;

        // 3. Pan-Tompkins: Derivative & Squaring
        // Simplified derivative for real-time: y(nT) = (1/8T)[-x(nT - 2T) - 2x(nT - T) + 2x(nT + T) + x(nT + 2T)]
        // Here we'll use a fast sequential approximation:
        double derivative = filtered - x2; 
        double squared = derivative * derivative;

        // 4. Pan-Tompkins: Moving Window Integration
        mwBuffer[mwIndex] = squared;
        mwIndex = (mwIndex + 1) % mwLength;
        double integrated = mwBuffer.reduce((a, b) => a + b) / mwLength;

        // 5. Adaptive Thresholding & Peak Detection
        if (samplesSinceLastPeak > refractoryPeriod) {
          if (integrated > adaptiveThreshold) {
            // R-PEAK DETECTED!
            
            // Calculate RR interval in milliseconds
            double rrIntervalMs = (samplesSinceLastPeak / 500.0) * 1000.0;
            
            // Filter physiologically implausible bounds (300ms - 2000ms)
            if (rrIntervalMs > 300 && rrIntervalMs < 2000) {
              currentWindowRrIntervals.add(rrIntervalMs);
            }

            // Update threshold (simplified: 50% of recent peak average)
            recentPeaks.add(integrated);
            if (recentPeaks.length > 8) recentPeaks.removeAt(0);
            adaptiveThreshold = (recentPeaks.reduce((a, b) => a + b) / recentPeaks.length) * 0.5;

            // Reset counter
            samplesSinceLastPeak = 0;
          }
        } else {
          // Decay threshold slowly if no peaks found to avoid getting stuck
          adaptiveThreshold *= 0.999;
        }

        // 6. 30-Second Window Check (15,000 samples)
        if (samplesInCurrentWindow >= 15000) {
          _computeAndSendRmssd(currentWindowRrIntervals, initData.mainStateSendPort);
          
          // Slide the window: Reset counters but keep PT state alive
          samplesInCurrentWindow = 0;
          currentWindowRrIntervals.clear();
        }
      }
    });
  }

  static void _computeAndSendRmssd(List<double> rrIntervals, SendPort mainPort) {
    if (rrIntervals.length < 20) {
      // PRD: Never display an RMSSD computed from fewer than 20 clean RR intervals.
      mainPort.send(RmssdResult(
        rmssd: 0, sd1: 0, sd2: 0, cleanRrCount: rrIntervals.length, isReliable: false,
      ));
      return;
    }

    // Calculate RMSSD
    double sumOfSquaredDifferences = 0.0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      double diff = rrIntervals[i + 1] - rrIntervals[i];
      sumOfSquaredDifferences += (diff * diff);
    }
    double rmssd = sqrt(sumOfSquaredDifferences / (rrIntervals.length - 1));

    // Calculate SDNN (Standard Deviation of NN intervals) needed for SD2
    double meanRr = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    double sumSqDiffMean = 0.0;
    for (double rr in rrIntervals) {
      sumSqDiffMean += pow(rr - meanRr, 2);
    }
    double sdnn = sqrt(sumSqDiffMean / rrIntervals.length);

    // Calculate SD1 and SD2 (Poincaré plot metrics for the AI Model)
    double sd1 = sqrt(0.5 * pow(rmssd, 2));
    // SD2 calculation safeguards against NaN if SDNN is somehow smaller
    double sd2Inner = (2 * pow(sdnn, 2)) - (0.5 * pow(rmssd, 2));
    double sd2 = sd2Inner > 0 ? sqrt(sd2Inner) : 0.0;

    // Send back to the Riverpod provider on the main thread
    mainPort.send(RmssdResult(
      rmssd: rmssd,
      sd1: sd1,
      sd2: sd2,
      cleanRrCount: rrIntervals.length,
      isReliable: true,
    ));
  }
}