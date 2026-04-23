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
  static SendPort? _bleSendPort; 

  static Future<SendPort> spawn(BleIsolateInit initData) async {
    final receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _isolateEntry,
      [receivePort.sendPort, initData],
      debugName: 'BleProcessorIsolate',
    );

    _bleSendPort = await receivePort.first as SendPort;
    return _bleSendPort!;
  }

  static void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _bleSendPort = null;
  }

  // ===========================================================================
  // ISOLATE ENTRY POINT
  // ===========================================================================

  static void _isolateEntry(List<dynamic> args) {
    final SendPort isolateHandshakePort = args[0];
    final BleIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    isolateHandshakePort.send(receivePort.sendPort); 

    final fileLock = Lock();
    int? lastSeqNum;
    int totalSamplesProcessed = 0;
    int packetCounter = 0;
    
    List<int> sampleBatch = [];

    final File csvFile = File(initData.sessionFilePath);
    if (!csvFile.existsSync()) {
      csvFile.createSync(recursive: true);
      csvFile.writeAsStringSync("timestamp_ms,sample_index,raw_adc_value,packet_seq,quality_flag\n");
    }
    
    final IOSink csvSink = csvFile.openWrite(mode: FileMode.append);

    receivePort.listen((message) {
      if (message == "CLOSE_SESSION") {
        csvSink.flush().then((_) => csvSink.close());
        return;
      }

      // CRITICAL FIX: flutter_blue_plus sends List<int>, not Uint8List directly.
      if (message is! List<int>) return; 
      
      final List<int> rawPacket = message;
      if (rawPacket.length != 42) return; 

      // Convert to ByteData for safe extraction
      final ByteData byteData = ByteData.sublistView(Uint8List.fromList(rawPacket));
      
      final int currentSeqNum = byteData.getUint16(0, Endian.little);
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      final StringBuffer csvBatchString = StringBuffer();

      // 3. Gap Detection Logic
      if (lastSeqNum != null) {
        int expectedSeq = (lastSeqNum! + 1) % 65536; 
        
        if (currentSeqNum != expectedSeq) {
          int packetsMissed = (currentSeqNum - expectedSeq) % 65536;
          if (packetsMissed < 0) packetsMissed += 65536; 

          if (packetsMissed > 1250) packetsMissed = 1250; 

          for (int p = 0; p < packetsMissed; p++) {
            int missedSeq = (expectedSeq + p) % 65536;
            for (int s = 0; s < 20; s++) {
              csvBatchString.writeln("$timestamp,${totalSamplesProcessed++},0,$missedSeq,0");
              sampleBatch.add(0); 
            }
          }
        }
      }

      lastSeqNum = currentSeqNum;

      // 4. Unpack 20 ECG Samples
      for (int i = 0; i < 20; i++) {
        final int sample = byteData.getInt16(2 + (i * 2), Endian.little);
        
        csvBatchString.writeln("$timestamp,${totalSamplesProcessed++},$sample,$currentSeqNum,1");
        sampleBatch.add(sample);
      }

      // 5. Synchronous Persistence (Thread-Safe)
      fileLock.synchronized(() async {
        csvSink.write(csvBatchString.toString());
        packetCounter++;
        
        if (packetCounter % 5 == 0) {
          await csvSink.flush();
        }
      });

      // 6. Forward to Signal Processor Isolate
      if (sampleBatch.length >= 150) {
        final batchToSend = sampleBatch.sublist(0, 150);
        initData.signalSendPort.send(batchToSend);
        
        sampleBatch = sampleBatch.sublist(150); 
      }
    });
  }
}