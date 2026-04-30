import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../shared/models/device_state.dart';
import '../../core/ble/kavach_connection_provider.dart';
import '../../core/ble/agna_connection_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both independent BLE streams simultaneously!
    final kavachState = ref.watch(kavachConnectionProvider);
    final agnaState = ref.watch(agnaConnectionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F5),
      appBar: AppBar(
        title: const Text('My Devices', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0, // Stops Material 3 from injecting colors when scrolling
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            "Manage your connected hardware. Dhritam supports simultaneous multi-device streams.",
            style: TextStyle(color: AppTheme.mutedGray, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 32),

          // --- DEVICE 1: KAVACH X (HRV) ---
          _buildDeviceCard(
            context: context,
            isDark: isDark,
            deviceName: "Kavach X",
            deviceType: "Vitals & HRV Band",
            icon: Icons.monitor_heart_rounded,
            iconColor: AppTheme.stressRed,
            state: kavachState,
            onAction: () {
              final notifier = ref.read(kavachConnectionProvider.notifier);
              if (kavachState == DeviceConnectionState.connected) {
                notifier.disconnect();
              } else if (kavachState == DeviceConnectionState.disconnected || kavachState == DeviceConnectionState.signalLost) {
                notifier.connectToKavach();
              }
            },
          ),

          const SizedBox(height: 24),

          // --- DEVICE 2: AGNA (BCI) ---
          _buildDeviceCard(
            context: context,
            isDark: isDark,
            deviceName: "Agna Headset",
            deviceType: "EEG Brain-Computer Interface",
            icon: Icons.psychology_rounded,
            iconColor: AppTheme.primaryPurple,
            state: agnaState,
            onAction: () {
              final notifier = ref.read(agnaConnectionProvider.notifier);
              
              if (agnaState == DeviceConnectionState.connected) {
                notifier.disconnect();
              } else if (agnaState == DeviceConnectionState.disconnected || agnaState == DeviceConnectionState.signalLost) {
                // --- MOCK SCANNER ---
                // In production, you'd trigger Bluetooth scan here and pass the 
                // discovered BluetoothDevice to notifier.connectToAgna(device).
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Scanning for Agna headsets..."),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper Widget to build identical, premium device cards
  Widget _buildDeviceCard({
    required BuildContext context,
    required bool isDark,
    required String deviceName,
    required String deviceType,
    required IconData icon,
    required Color iconColor,
    required DeviceConnectionState state,
    required VoidCallback onAction,
  }) {
    final isConnected = state == DeviceConnectionState.connected;
    final isConnecting = state == DeviceConnectionState.connecting || state == DeviceConnectionState.scanning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isConnected ? iconColor.withValues(alpha: 0.3) : AppTheme.mutedGray.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: isConnected ? iconColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected ? iconColor.withValues(alpha: 0.1) : AppTheme.mutedGray.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isConnected ? iconColor : AppTheme.mutedGray, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(deviceType, style: const TextStyle(color: AppTheme.mutedGray, fontSize: 13)),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppTheme.recoveryTeal.withValues(alpha: 0.1) : AppTheme.mutedGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppTheme.recoveryTeal : AppTheme.mutedGray,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? "Active" : "Offline",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? AppTheme.recoveryTeal : AppTheme.mutedGray,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isConnecting ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.transparent : iconColor,
                foregroundColor: isConnected ? AppTheme.stressRed : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isConnected ? AppTheme.stressRed : Colors.transparent),
                ),
              ),
              child: isConnecting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    isConnected ? "Disconnect" : "Scan & Connect",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
            ),
          )
        ],
      ),
    );
  }
}