import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'theme/app_theme.dart';
import 'features/home/main_scaffold.dart'; 
// NEW: Import the permissions screen
import 'features/permissions/permissions_screen.dart'; 

class DhritamApp extends StatelessWidget {
  const DhritamApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the app to provide the foreground task context to the OS
    return WithForegroundTask(
      child: MaterialApp(
        title: 'Dhritam',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, 
        // UPDATED: The app now launches the Permissions Screen first.
        // Once granted, it automatically routes to the MainScaffold!
        home: const PermissionsScreen(nextScreen: MainScaffold()), 
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}