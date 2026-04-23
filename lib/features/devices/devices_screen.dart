import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ble/kavach_connection_provider.dart';
import '../../shared/models/device_state.dart';
import '../../theme/app_theme.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(kavachConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        backgroundColor: AppTheme.bgOffWhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kavach X', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildConnectionCard(context, ref, connectionState),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, WidgetRef ref, DeviceConnectionState state) {
    Color statusColor;
    String statusText;

    switch (state) {
      case DeviceConnectionState.connected:
        statusColor = AppTheme.recoveryTeal;
        statusText = 'Connected';
        break;
      case DeviceConnectionState.scanning:
      case DeviceConnectionState.connecting:
        statusColor = AppTheme.moderateAmber;
        statusText = 'Connecting...';
        break;
      case DeviceConnectionState.signalLost:
        statusColor = AppTheme.stressRed;
        statusText = 'Signal Lost';
        break;
      case DeviceConnectionState.disconnected:
        // FIX: Removed "default:" and added "break;" because the switch is exhaustive
        statusColor = AppTheme.mutedGray;
        statusText = 'Disconnected';
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.monitor_heart, color: statusColor, size: 32),
        title: Text(statusText, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: state == DeviceConnectionState.connected 
                ? AppTheme.bgOffWhite 
                : AppTheme.primaryPurple,
            foregroundColor: state == DeviceConnectionState.connected 
                ? AppTheme.stressRed 
                : AppTheme.cardWhite,
          ),
          onPressed: () {
            if (state == DeviceConnectionState.connected) {
              ref.read(kavachConnectionProvider.notifier).disconnect();
            } else if (state == DeviceConnectionState.disconnected || state == DeviceConnectionState.signalLost) {
              ref.read(kavachConnectionProvider.notifier).connectToKavach();
            }
          },
          child: Text(state == DeviceConnectionState.connected ? 'Disconnect' : 'Connect'),
        ),
      ),
    );
  }
}