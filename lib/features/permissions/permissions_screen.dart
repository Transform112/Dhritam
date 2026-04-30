import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  final Widget nextScreen; // The screen to go to after permissions are granted

  const PermissionsScreen({super.key, required this.nextScreen});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    // If we are not on Android, or if permissions are already granted, skip this screen.
    if (!Platform.isAndroid) {
      _navigateToNext();
      return;
    }

    bool bleScan = await Permission.bluetoothScan.isGranted;
    bool bleConnect = await Permission.bluetoothConnect.isGranted;
    bool location = await Permission.location.isGranted; // Required by Android for BLE
    bool notifications = await Permission.notification.isGranted;

    if (bleScan && bleConnect && location && notifications) {
      _navigateToNext();
    } else {
      setState(() {
        _isLoading = false; // Show the UI
      });
    }
  }

  Future<void> _requestPermissions() async {
    // 1. Request the permissions from the OS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
    ].request();

    // 2. Check if the user granted the core requirements
    bool isBleGranted = statuses[Permission.bluetoothScan]?.isGranted == true && 
                        statuses[Permission.bluetoothConnect]?.isGranted == true;
    bool isLocationGranted = statuses[Permission.location]?.isGranted == true;

    // We proceed if the hardware connection permissions are granted. 
    // (Notifications are technically optional for the app to function, but highly recommended).
    if (isBleGranted && isLocationGranted) {
      _navigateToNext();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bluetooth and Location are required to connect to the Kavach X band."),
            backgroundColor: AppTheme.moderateAmber,
          ),
        );
      }
    }
  }

  void _navigateToNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgOffWhite,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : AppTheme.bgOffWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, size: 48, color: AppTheme.primaryPurple),
              ),
              const SizedBox(height: 32),
              Text(
                "Let's get connected.",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              Text(
                "Dhritam needs a few permissions to sync with your Kavach X band and analyze your biometrics in the background.",
                style: TextStyle(fontSize: 16, color: AppTheme.mutedGray, height: 1.5),
              ),
              const SizedBox(height: 48),

              // Permission Explanations
              _buildPermissionRow(
                icon: Icons.bluetooth_connected_rounded,
                title: "Bluetooth & Location",
                description: "Required to scan for and connect to your Kavach X band. Location is mandated by Android for Bluetooth scanning.",
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildPermissionRow(
                icon: Icons.notifications_active_rounded,
                title: "Notifications",
                description: "Allows Dhritam to run background ML analysis and alert you when your session is complete.",
                isDark: isDark,
              ),

              const Spacer(),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({required IconData icon, required String title, required String description, required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.mutedGray.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: AppTheme.recoveryTeal, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 14, color: AppTheme.mutedGray, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}