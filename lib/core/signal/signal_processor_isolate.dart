import 'dart:isolate';
import 'dart:math';

import 'biquad_filter.dart'; // Import the DSP engine we just built

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
  final int currentBpm; // NEW: Added Heart Rate
  final int cleanRrCount;
  final bool isReliable;

  RmssdResult({
    required this.rmssd,
    required this.sd1,
    required this.sd2,
    required this.currentBpm,
    required this.cleanRrCount,
    required this.isReliable,
  });
}

class SignalProcessorIsolate {
  static Isolate? _isolate;
  static SendPort? _signalSendPort;

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
  // ISOLATE ENTRY POINT - PAN-TOMPKINS ENGINE
  // ===========================================================================

  static void _isolateEntry(List<dynamic> args) {
    final SendPort handshakePort = args[0];
    final SignalIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    handshakePort.send(receivePort.sendPort);

    // --- Instantiate the Biquad Filters ---
    final notchFilter = KavachFilters.create50HzNotch();
    final bandpassFilter = KavachFilters.createEcgBandpass();

    // --- Global Window State (15,000 samples = 30s) ---
    int samplesInCurrentWindow = 0;
    List<double> currentWindowRrIntervals = [];
    
    // --- Pan-Tompkins: Derivative Buffer ---
    // Holds the last 5 samples for the 5-point derivative
    List<double> derivBuffer = List.filled(5, 0.0, growable: true);
    
    // --- Pan-Tompkins: Moving Window Integration (MWI) ---
    // 150ms window at 500Hz = 75 samples
    final int mwLength = 75;
    List<double> mwBuffer = List.filled(mwLength, 0.0);
    int mwIndex = 0;
    double mwSum = 0.0; // Running sum optimization (O(1) instead of O(N))
    
    // --- Pan-Tompkins: Adaptive Peak Detection ---
    double spki = 0.0; // Signal Peak estimate
    double npki = 0.0; // Noise Peak estimate
    double threshold1 = 0.0; // Primary detection threshold
    
    double mwiPrev = 0.0;
    double mwiPrev2 = 0.0;
    
    int samplesSinceLastPeak = 0;
    final int refractoryPeriod = 100; // 200ms at 500Hz

    receivePort.listen((message) {
      if (message is! List<int>) return; 
      
      final List<int> rawBatch = message;

      for (int i = 0; i < rawBatch.length; i++) {
        samplesInCurrentWindow++;
        samplesSinceLastPeak++;

        // 1. Convert ADC to mV
        double signal = (rawBatch[i] / 4095.0) * 3300.0 - 1650.0;

        // 2. Apply IIR Biquad Cascade
        double notched = notchFilter.process(signal);
        double filtered = bandpassFilter.process(notched);

        // 3. PT Derivative: H(z) = (1/8T)(-z^-2 - 2z^-1 + 2z^1 + z^2)
        derivBuffer.insert(0, filtered);
        derivBuffer.removeLast();
        double derivative = (2.0 * derivBuffer[0] + derivBuffer[1] - derivBuffer[3] - 2.0 * derivBuffer[4]) / 8.0;
        
        // 4. PT Squaring
        double squared = derivative * derivative;

        // 5. PT Moving Window Integration (Running Sum)
        mwSum -= mwBuffer[mwIndex];
        mwBuffer[mwIndex] = squared;
        mwSum += squared;
        mwIndex = (mwIndex + 1) % mwLength;
        
        double mwi = mwSum / mwLength;

        // 6. PT Adaptive Thresholding & Peak Search
        // Check if the PREVIOUS sample was a local maximum
        bool isLocalMax = (mwiPrev > mwi) && (mwiPrev > mwiPrev2);

        if (isLocalMax && samplesSinceLastPeak > refractoryPeriod) {
          if (mwiPrev > threshold1) {
            // Valid R-Peak Detected!
            spki = 0.125 * mwiPrev + 0.875 * spki;
            threshold1 = npki + 0.25 * (spki - npki);

            double rrIntervalMs = (samplesSinceLastPeak / 500.0) * 1000.0;
            
            // Physiological filter
            if (rrIntervalMs > 300 && rrIntervalMs < 2000) {
              currentWindowRrIntervals.add(rrIntervalMs);
            }
            
            samplesSinceLastPeak = 0; // Reset refractory timer
          } else {
            // Noise Peak (Local max, but below signal threshold)
            npki = 0.125 * mwiPrev + 0.875 * npki;
            threshold1 = npki + 0.25 * (spki - npki);
          }
        } else if (!isLocalMax && samplesSinceLastPeak > refractoryPeriod * 3) {
          // Fallback: Slowly lower threshold if no peaks are found for a long time
          threshold1 *= 0.999;
        }

        // Shift MWI history for next loop
        mwiPrev2 = mwiPrev;
        mwiPrev = mwi;

        // 7. 30-Second Epoch Evaluation
        if (samplesInCurrentWindow >= 2500) {
          _computeAndSendRmssd(currentWindowRrIntervals, initData.mainStateSendPort);
          
          samplesInCurrentWindow = 0;
          currentWindowRrIntervals.clear();
        }
      }
    });
  }

  static void _computeAndSendRmssd(List<double> rrIntervals, SendPort mainPort) {
    if (rrIntervals.length < 3) {
      mainPort.send(RmssdResult(
        rmssd: 0, sd1: 0, sd2: 0, currentBpm: 0, cleanRrCount: rrIntervals.length, isReliable: false,
      ));
      return;
    }

    // RMSSD
    double sumSqDiff = 0.0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      double diff = rrIntervals[i + 1] - rrIntervals[i];
      sumSqDiff += (diff * diff);
    }
    double rmssd = sqrt(sumSqDiff / (rrIntervals.length - 1));

    // SDNN
    double meanRr = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    double sumSqDiffMean = 0.0;
    for (double rr in rrIntervals) {
      sumSqDiffMean += pow(rr - meanRr, 2);
    }
    double sdnn = sqrt(sumSqDiffMean / rrIntervals.length);

    // Poincaré 
    double sd1 = sqrt(0.5 * pow(rmssd, 2));
    double sd2Inner = (2 * pow(sdnn, 2)) - (0.5 * pow(rmssd, 2));
    double sd2 = sd2Inner > 0 ? sqrt(sd2Inner) : 0.0;

    // Heart Rate calculation
    int bpm = (60000.0 / meanRr).round();

    mainPort.send(RmssdResult(
      rmssd: rmssd,
      sd1: sd1,
      sd2: sd2,
      currentBpm: bpm,
      cleanRrCount: rrIntervals.length,
      isReliable: true,
    ));
  }
}