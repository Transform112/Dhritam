import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'theme/app_theme.dart';
import 'features/home/main_scaffold.dart'; // NEW: Import the root scaffold

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
        home: const MainScaffold(), // UPDATED: Point to our new Navigation Scaffold
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}