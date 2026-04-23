import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'shared/widgets/main_layout.dart';

class DhritamApp extends StatelessWidget {
  const DhritamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhritam',
      theme: AppTheme.lightTheme, // Assuming you created this from the earlier step
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // PRD rule: respect system settings
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}