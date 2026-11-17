import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_role.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/screens/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../products/screens/products_screen.dart';
import '../reports/screens/reports_screen.dart';
import '../sales/screens/sales_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../team/screens/team_screen.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String? _roleKey;
  List<_NavItem> _items = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<AuthProvider>().profile;
    final roleKey = profile?.role.dbValue ?? 'none';
    if (_roleKey == roleKey) return;
    _roleKey = roleKey;
    _items = _itemsForRole(profile?.role);
    _selectedIndex = 0;
  }

  List<_NavItem> _itemsForRole(UserRole? role) {
    final items = <_NavItem>[
      _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        builder: () => const DashboardScreen(),
      ),
    ];

    if (role == UserRole.admin || role == UserRole.cashier) {
      items.add(
        _NavItem(
          label: 'POS',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          builder: () => const PosScreen(),
        ),
      );
      items.add(
        _NavItem(
          label: 'Sales',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          builder: () => const SalesScreen(),
        ),
      );
      items.add(
        _NavItem(
          label: 'Customers',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          builder: () => const CustomersScreen(),
        ),
      );
    }

    if (role == UserRole.admin || role == UserRole.inventoryManager) {
      items.add(
        _NavItem(
          label: 'Products',
          icon: Icons.chair_outlined,
          selectedIcon: Icons.chair,
          builder: () => const ProductsScreen(),
        ),
      );
      items.add(
        _NavItem(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: () => const InventoryScreen(),
        ),
      );
    }

    if (role == UserRole.admin) {
      items.add(
        _NavItem(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          builder: () => const ReportsScreen(),
        ),
      );
      items.add(
        _NavItem(
          label: 'Team',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          builder: () => const TeamScreen(),
        ),
      );
      items.add(
        _NavItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          builder: () => const SettingsScreen(),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final items = _items;
    final safeIndex = _selectedIndex.clamp(0, items.isEmpty ? 0 : items.length - 1);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: items.isEmpty ? 0 : safeIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Column(
                children: [
                  Icon(Icons.chair_alt_rounded,
                      color: theme.colorScheme.primary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    "Rhonalyn's",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (profile != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            profile.role.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout),
                    onPressed: auth.isWorking ? null : () => auth.signOut(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No modules available'))
                : items[safeIndex].builder(),
          ),
        ],
      ),
    );
  }
}
