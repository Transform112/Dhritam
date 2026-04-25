import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

class BleIsolateInit {
  final SendPort mainSendPort;
  final SendPort signalSendPort;

  BleIsolateInit({required this.mainSendPort, required this.signalSendPort});
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

  static void _isolateEntry(List<dynamic> args) async {
    final SendPort isolateHandshakePort = args[0];
    final BleIsolateInit initData = args[1];

    final receivePort = ReceivePort();
    isolateHandshakePort.send(receivePort.sendPort); 

    // --- ML EXPORTER STATE ---
    bool isRecording = false;
    IOSink? fileSink;
    StringBuffer csvBuffer = StringBuffer();
    int bufferCount = 0;

    List<int> sampleBatch = [];

    receivePort.listen((message) async {
      // 1. Handle Command Strings from the Main Thread
      if (message is String) {
        if (message.startsWith("START_RECORDING|")) {
          final path = message.split("|")[1];
          final rawFile = File(path);
          if (!rawFile.existsSync()) rawFile.createSync(recursive: true);
          fileSink = rawFile.openWrite(mode: FileMode.append);
          fileSink?.writeln("timestamp_ms,raw_ecg");
          isRecording = true;
          return;
        } 
        else if (message == "STOP_RECORDING" || message == "CLOSE_SESSION") {
          isRecording = false;
          if (fileSink != null) {
            fileSink?.write(csvBuffer.toString());
            await fileSink?.flush();
            await fileSink?.close();
            fileSink = null;
            csvBuffer.clear();
            bufferCount = 0;
          }
          if (message == "CLOSE_SESSION") return;
        }
      }

      // 2. Handle Binary Data
      if (message is! List<int>) return; 
      final List<int> rawPacket = message;
      if (rawPacket.length < 2) return; 

      final ByteData byteData = ByteData.sublistView(Uint8List.fromList(rawPacket));
      int maxSamples = (rawPacket.length - 2) ~/ 2;
      if (maxSamples > 20) maxSamples = 20; 

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < maxSamples; i++) {
        final int sample = byteData.getInt16(2 + (i * 2), Endian.little);
        sampleBatch.add(sample);
        
        // ONLY save to buffer if the user hit the Record button
        if (isRecording) {
          csvBuffer.writeln("$timestamp,$sample");
          bufferCount++;
        }
      }

      // Chunked Disk Writing
      if (isRecording && bufferCount >= 1000) {
        fileSink?.write(csvBuffer.toString());
        csvBuffer.clear();
        bufferCount = 0;
      }

      // Forward to DSP Math Engine (This runs continuously, recording or not)
      if (sampleBatch.length >= 150) {
        final batchToSend = sampleBatch.sublist(0, 150);
        initData.signalSendPort.send(batchToSend);
        sampleBatch = sampleBatch.sublist(150); 
      }
    });
  }
}