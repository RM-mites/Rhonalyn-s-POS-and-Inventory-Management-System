import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/startup/startup_screen.dart';

class RhonalynsApp extends StatelessWidget {
  const RhonalynsApp({super.key, this.initError});

  /// Non-null when the app could not initialise (for example, missing
  /// Supabase credentials). Displayed by [StartupScreen].
  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Rhonalyn's POS & Inventory",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StartupScreen(error: initError),
    );
  }
}
