import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../shared/models/device_state.dart';
import '../../shared/models/eeg_state.dart';

// ==========================================
// 1. The EEG Data Stream Provider 
// ==========================================
class EegNotifier extends Notifier<EegState> {
  @override
  EegState build() => EegState.empty();

  void updateState(EegState newState) {
    state = newState;
  }
}

final eegProvider = NotifierProvider<EegNotifier, EegState>(() {
  return EegNotifier();
});

// ==========================================
// 2. The Agna Connection Provider
// ==========================================
class AgnaConnectionNotifier extends Notifier<DeviceConnectionState> {
  BluetoothDevice? _agnaDevice;
  StreamSubscription<List<int>>? _eegSubscription;

  // Replace these with actual Agna UUIDs when hardware is final
  final String agnaServiceUuid = "0000FEA0-0000-1000-8000-00805F9B34FB"; 
  final String eegCharacteristicUuid = "0000FEA1-0000-1000-8000-00805F9B34FB"; 

  @override
  DeviceConnectionState build() {
    ref.onDispose(() {
      _eegSubscription?.cancel();
      _agnaDevice?.disconnect(); 
    });
    return DeviceConnectionState.disconnected;
  }

  Future<void> connectToAgna(BluetoothDevice device) async {
    state = DeviceConnectionState.connecting;
    _agnaDevice = device;

    try {
      // FIXED: Using the actual License.free enum required by v2.1+
      await device.connect(autoConnect: false, license: License.free); 
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? eegChar;

      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == agnaServiceUuid.toUpperCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == eegCharacteristicUuid.toUpperCase()) {
              eegChar = characteristic;
            }
          }
        }
      }

      if (eegChar != null) {
        await eegChar.setNotifyValue(true);
        _eegSubscription = eegChar.lastValueStream.listen(_parseEegPacket);
        state = DeviceConnectionState.connected;
      } else {
        await disconnect();
        state = DeviceConnectionState.disconnected; 
      }
    } catch (e) {
      await disconnect();
      state = DeviceConnectionState.disconnected;
    }
  }

  void _parseEegPacket(List<int> value) {
    if (value.isEmpty) return;

    // --- MOCK PARSER ---
    if (value.length >= 3) {
      final alpha = value[0].toDouble();
      final beta = value[1].toDouble();
      final theta = value[2].toDouble();
      
      final isReliable = value.length >= 4 ? value[3] == 1 : true;

      ref.read(eegProvider.notifier).updateState(EegState(
        alpha: alpha,
        beta: beta,
        theta: theta,
        isReliable: isReliable,
      ));
    }
  }

  Future<void> disconnect() async {
    await _eegSubscription?.cancel();
    await _agnaDevice?.disconnect(); 
    _agnaDevice = null;
    ref.read(eegProvider.notifier).updateState(EegState.empty());
    state = DeviceConnectionState.disconnected;
  }
}

final agnaConnectionProvider = NotifierProvider<AgnaConnectionNotifier, DeviceConnectionState>(() {
  return AgnaConnectionNotifier();
});