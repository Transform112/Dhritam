import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/models/device_state.dart';
import 'ble_processor_isolate.dart';
import '../signal/signal_processor_isolate.dart';
import '../../features/home/providers/rmssd_provider.dart';

const String kavachServiceUuid = "abcdef01-1234-5678-1234-56789abcdef0";
const String kavachCharacteristicUuid = "abcdef02-1234-5678-1234-56789abcdef0"; 
const String kavachDeviceName = "Kavach X";

// Upgraded to NotifierProvider
final kavachConnectionProvider = NotifierProvider<KavachConnectionNotifier, DeviceConnectionState>(() {
  return KavachConnectionNotifier();
});

class KavachConnectionNotifier extends Notifier<DeviceConnectionState> {
  BluetoothDevice? _kavachDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  
  SendPort? _bleIsolateSendPort;
  ReceivePort? _mainRmssdReceivePort;

  @override
  DeviceConnectionState build() {
    // Replacement for the old dispose() method
    ref.onDispose(() {
      disconnect();
    });
    return DeviceConnectionState.disconnected;
  }

  Future<void> connectToKavach() async {
    if (state == DeviceConnectionState.connected || state == DeviceConnectionState.connecting) return;
    state = DeviceConnectionState.scanning;

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      state = DeviceConnectionState.disconnected;
      return; 
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == kavachDeviceName || 
            r.advertisementData.serviceUuids.contains(Guid(kavachServiceUuid))) {
          await _stopScan();
          await _connect(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(kavachServiceUuid)],
      timeout: const Duration(seconds: 15),
    );

    if (state == DeviceConnectionState.scanning) {
      state = DeviceConnectionState.disconnected;
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    _kavachDevice = device;
    state = DeviceConnectionState.connecting;

    try {
      // CRITICAL FIX: The new flutter_blue_plus API requires the license parameter
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10), license: License.free);
      
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
        await device.requestMtu(247); 
      }

      _listenToConnectionState();
      await _startDataStream(device);

      state = DeviceConnectionState.connected;
    } catch (e) {
      await disconnect();
    }
  }

  Future<void> _startDataStream(BluetoothDevice device) async {
    final directory = await getApplicationDocumentsDirectory();
    final sessionDir = Directory('${directory.path}/sessions');
    if (!sessionDir.existsSync()) {
      sessionDir.createSync(recursive: true);
    }
    
    final now = DateTime.now();
    final timestamp = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    final filePath = '${sessionDir.path}/${timestamp}_session.csv';

    _mainRmssdReceivePort = ReceivePort();
    _mainRmssdReceivePort!.listen((message) {
      if (message is RmssdResult) {
        // Correctly update the new NotifierProvider
        ref.read(rmssdProvider.notifier).updateState(message);
      }
    });

    final signalSendPort = await SignalProcessorIsolate.spawn(
      SignalIsolateInit(mainStateSendPort: _mainRmssdReceivePort!.sendPort),
    );

    _bleIsolateSendPort = await BleProcessorIsolate.spawn(
      BleIsolateInit(
        mainSendPort: ReceivePort().sendPort, 
        signalSendPort: signalSendPort, 
        sessionFilePath: filePath,
      ),
    );

    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? ecgCharacteristic;

    for (var service in services) {
      if (service.uuid == Guid(kavachServiceUuid)) {
        for (var char in service.characteristics) {
          if (char.uuid == Guid(kavachCharacteristicUuid)) {
            ecgCharacteristic = char;
            break;
          }
        }
      }
    }

    if (ecgCharacteristic == null) {
      throw Exception("ECG Characteristic not found on device.");
    }

    await ecgCharacteristic.setNotifyValue(true);
    _characteristicSubscription = ecgCharacteristic.onValueReceived.listen((value) {
      _bleIsolateSendPort?.send(value); 
    });
  }

  void _listenToConnectionState() {
    _connectionSubscription?.cancel();
    _connectionSubscription = _kavachDevice?.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        state = DeviceConnectionState.signalLost;
        _characteristicSubscription?.cancel();
        _bleIsolateSendPort?.send("CLOSE_SESSION");
      }
    });
  }

  Future<void> disconnect() async {
    await _stopScan();
    await _characteristicSubscription?.cancel();
    
    _bleIsolateSendPort?.send("CLOSE_SESSION");
    
    await Future.delayed(const Duration(milliseconds: 100));
    BleProcessorIsolate.kill();
    _mainRmssdReceivePort?.close();
    SignalProcessorIsolate.kill();

    await _connectionSubscription?.cancel();
    if (_kavachDevice != null) {
      await _kavachDevice!.disconnect();
    }
    
    ref.read(rmssdProvider.notifier).updateState(null);
    state = DeviceConnectionState.disconnected;
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
  }
}