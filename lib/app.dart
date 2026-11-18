import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/customers/providers/customers_provider.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/pos/providers/cart_provider.dart';
import 'features/products/providers/catalog_provider.dart';
import 'features/reports/providers/reports_provider.dart';
import 'features/sales/providers/sales_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/team/providers/team_provider.dart';
import 'features/startup/startup_screen.dart';

class RhonalynsApp extends StatelessWidget {
  const RhonalynsApp({super.key, this.initError});

  /// Non-null when the app could not initialise (for example, missing
  /// Supabase credentials). Displayed by [StartupScreen].
  final String? initError;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: "Rhonalyn's Sales & Inventory",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: initError != null
            ? StartupScreen(error: initError)
            : const AuthGate(),
      ),
    );
    if (initError != null) return app;
    // Providers wrap MaterialApp so dialogs (which are pushed as sibling
    // routes under the Navigator) can access them.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: app,
    );
  }
}
