import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/products/providers/catalog_provider.dart';
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
      home: initError != null
          ? StartupScreen(error: initError)
          : MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => AuthProvider()),
                ChangeNotifierProvider(create: (_) => CatalogProvider()),
                ChangeNotifierProvider(create: (_) => InventoryProvider()),
              ],
              child: const AuthGate(),
            ),
    );
  }
}
