import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:synchronized/synchronized.dart';

/// The initialization payload passed from the Main Thread to the Ble Isolate
class BleIsolateInit {
  final SendPort mainSendPort;
  final SendPort signalSendPort;
  final String sessionFilePath;

  BleIsolateInit({
    required this.mainSendPort,
    required this.signalSendPort,
    required this.sessionFilePath,
  });
}

class BleProcessorIsolate {
  static Isolate? _isolate;
  static SendPort? _bleSendPort; // Port to send raw packets from Main to this Isolate

  /// Starts the isolate and returns the SendPort so the BLE connection manager
  /// can stream raw Uint8List packets to it.
  static Future<SendPort> spawn(BleIsolateInit initData) async {
    final receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _isolateEntry,
      [receivePort.sendPort, initData],
      debugName: 'BleProcessorIsolate',
    );

    // Wait for the isolate to send back its listening port
    _bleSendPort = await receivePort.first as SendPort;
    return _bleSendPort!;
  }

  static void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _bleSendPort = null;
  }

  // ===========================================================================
  // ISOLATE ENTRY POINT - NOTHING BELOW THIS LINE RUNS ON THE MAIN THREAD
  // ===========================================================================

  static void _isolateEntry(List<dynamic> args) {
    final SendPort isolateHandshakePort = args[0];
    final BleIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    isolateHandshakePort.send(receivePort.sendPort); // Complete handshake

    // 1. Initialization
    final fileLock = Lock();
    int? lastSeqNum;
    int totalSamplesProcessed = 0;
    int packetCounter = 0;
    
    // Batch buffer for the Signal Isolate (150 samples)
    List<int> sampleBatch = [];

    // Open the "Sacred" CSV with append mode
    final File csvFile = File(initData.sessionFilePath);
    if (!csvFile.existsSync()) {
      csvFile.createSync(recursive: true);
      // Write CSV Header
      csvFile.writeAsStringSync("timestamp_ms,sample_index,raw_adc_value,packet_seq,quality_flag\n");
    }
    
    final IOSink csvSink = csvFile.openWrite(mode: FileMode.append);

    // 2. Packet Processing Loop
    receivePort.listen((message) {
      if (message == "CLOSE_SESSION") {
        csvSink.flush().then((_) => csvSink.close());
        return;
      }

      if (message is! Uint8List) return;
      
      final Uint8List packet = message;
      if (packet.length != 42) return; // Drop malformed packets immediately

      final ByteData byteData = ByteData.sublistView(packet);
      final int currentSeqNum = byteData.getUint16(0, Endian.little);
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      final StringBuffer csvBatchString = StringBuffer();

      // 3. Gap Detection Logic
      if (lastSeqNum != null) {
        int expectedSeq = (lastSeqNum! + 1) % 65536; // Sequence rolls over at 16-bit max
        
        if (currentSeqNum != expectedSeq) {
          int packetsMissed = (currentSeqNum - expectedSeq) % 65536;
          if (packetsMissed < 0) packetsMissed += 65536; // Handle negative modulo

          // Cap massive gaps (e.g., device disconnected for 10 minutes) 
          // to prevent memory exhaustion when generating padding.
          if (packetsMissed > 1250) packetsMissed = 1250; // Cap at ~50 seconds of padding

          // Insert zero-padded rows with quality_flag = 0
          for (int p = 0; p < packetsMissed; p++) {
            int missedSeq = (expectedSeq + p) % 65536;
            for (int s = 0; s < 20; s++) {
              csvBatchString.writeln("$timestamp,${totalSamplesProcessed++},0,$missedSeq,0");
              sampleBatch.add(0); // Send 0s to the signal processor to maintain time alignment
            }
          }
        }
      }

      lastSeqNum = currentSeqNum;

      // 4. Unpack 20 ECG Samples
      for (int i = 0; i < 20; i++) {
        // Offset is 2 bytes (for seq num) + (i * 2 bytes per sample)
        final int sample = byteData.getInt16(2 + (i * 2), Endian.little);
        
        // Write to CSV buffer (quality_flag = 1)
        csvBatchString.writeln("$timestamp,${totalSamplesProcessed++},$sample,$currentSeqNum,1");
        
        // Add to Signal Processor batch
        sampleBatch.add(sample);
      }

      // 5. Synchronous Persistence (Thread-Safe)
      fileLock.synchronized(() async {
        csvSink.write(csvBatchString.toString());
        packetCounter++;
        
        // Flush physically to disk every 5 packets (~every 200ms)
        if (packetCounter % 5 == 0) {
          await csvSink.flush();
        }
      });

      // 6. Forward to Signal Processor Isolate
      if (sampleBatch.length >= 150) {
        // Send a copy of exactly 150 samples. 
        // If we padded zeros, it might be larger, so we slice it.
        final batchToSend = sampleBatch.sublist(0, 150);
        initData.signalSendPort.send(batchToSend);
        
        // Keep any remaining samples for the next batch
        sampleBatch = sampleBatch.sublist(150); 
      }
    });
  }
}