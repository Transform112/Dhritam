import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

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
    _isolate = await Isolate.spawn(_isolateEntry, [receivePort.sendPort, initData]);
    _bleSendPort = await receivePort.first as SendPort;
    return _bleSendPort!;
  }

  static void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _bleSendPort = null;
  }

  static void _isolateEntry(List<dynamic> args) {
    final SendPort isolateHandshakePort = args[0];
    final BleIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    isolateHandshakePort.send(receivePort.sendPort); 

    List<int> sampleBatch = [];
    int debugPrintCount = 0; // NEW: Counter for diagnostics

    receivePort.listen((message) {
      if (message == "CLOSE_SESSION") return;
      if (message is! List<int>) return; 
      
      final List<int> rawPacket = message;

      // NEW: Print the first 5 packets to see what the ESP32 is actually sending!
      if (debugPrintCount < 5) {
        print("🚨 BLE ISOLATE RAW PACKET LENGTH: ${rawPacket.length} bytes");
        debugPrintCount++;
      }

      // Relaxed check: As long as there is data, try to parse it.
      if (rawPacket.length < 2) return; 

      final ByteData byteData = ByteData.sublistView(Uint8List.fromList(rawPacket));
      
      // Safely extract as many 16-bit samples as the packet allows
      // (Subtracting 2 bytes for the sequence number, divided by 2 bytes per int)
      int maxSamples = (rawPacket.length - 2) ~/ 2;
      if (maxSamples > 20) maxSamples = 20; 

      for (int i = 0; i < maxSamples; i++) {
        final int sample = byteData.getInt16(2 + (i * 2), Endian.little);
        sampleBatch.add(sample);
      }

      if (sampleBatch.length >= 150) {
        final batchToSend = sampleBatch.sublist(0, 150);
        initData.signalSendPort.send(batchToSend);
        sampleBatch = sampleBatch.sublist(150); 
      }
    });
  }
}