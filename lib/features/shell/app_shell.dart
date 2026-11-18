import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_role.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/screens/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../products/screens/products_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../reports/screens/reports_screen.dart';
import '../sales/screens/sales_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../team/screens/team_screen.dart';

enum _Destination {
  dashboard,
  pos,
  sales,
  customers,
  products,
  inventory,
  reports,
  team,
  settings,
  profile,
}

class _NavItem {
  const _NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final _Destination key;
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
  String? _roleKey;
  _Destination? _selected;
  Map<_Destination, _NavItem> _items = const {};
  List<_Destination> _bottomKeys = const [_Destination.dashboard, _Destination.profile];
  List<_Destination> _drawerKeys = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = context.read<AuthProvider>().profile?.role;
    final roleKey = role?.dbValue ?? 'none';
    if (_roleKey == roleKey) return;
    _roleKey = roleKey;
    _items = _itemsForRole(role);
    _bottomKeys = _bottomKeysForRole(role);
    _drawerKeys = _drawerKeysForRole(role);
    if (_selected == null || !_items.containsKey(_selected)) {
      _selected = _Destination.dashboard;
    }
  }

  Map<_Destination, _NavItem> _itemsForRole(UserRole? role) {
    final items = <_Destination, _NavItem>{
      _Destination.dashboard: const _NavItem(
        key: _Destination.dashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        builder: DashboardScreen.new,
      ),
      _Destination.profile: const _NavItem(
        key: _Destination.profile,
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        builder: ProfileScreen.new,
      ),
    };

    if (role == UserRole.admin || role == UserRole.cashier) {
      items.addAll({
        _Destination.pos: const _NavItem(
          key: _Destination.pos,
          label: 'Sales',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          builder: PosScreen.new,
        ),
        _Destination.sales: const _NavItem(
          key: _Destination.sales,
          label: 'Sales History',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          builder: SalesScreen.new,
        ),
        _Destination.customers: const _NavItem(
          key: _Destination.customers,
          label: 'Customers',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          builder: CustomersScreen.new,
        ),
      });
    }

    if (role == UserRole.admin || role == UserRole.inventoryManager) {
      items.addAll({
        _Destination.products: const _NavItem(
          key: _Destination.products,
          label: 'Products',
          icon: Icons.chair_outlined,
          selectedIcon: Icons.chair,
          builder: ProductsScreen.new,
        ),
        _Destination.inventory: const _NavItem(
          key: _Destination.inventory,
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: InventoryScreen.new,
        ),
      });
    }

    if (role == UserRole.admin) {
      items.addAll({
        _Destination.reports: const _NavItem(
          key: _Destination.reports,
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          builder: ReportsScreen.new,
        ),
        _Destination.team: const _NavItem(
          key: _Destination.team,
          label: 'Team',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          builder: TeamScreen.new,
        ),
        _Destination.settings: const _NavItem(
          key: _Destination.settings,
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          builder: SettingsScreen.new,
        ),
      });
    }

    return items;
  }

  List<_Destination> _bottomKeysForRole(UserRole? role) {
    if (role == UserRole.admin) {
      return const [
        _Destination.dashboard,
        _Destination.reports,
        _Destination.team,
        _Destination.profile,
      ];
    }
    return const [_Destination.dashboard, _Destination.profile];
  }

  List<_Destination> _drawerKeysForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return const [
          _Destination.pos,
          _Destination.sales,
          _Destination.customers,
          _Destination.products,
          _Destination.inventory,
          _Destination.settings,
        ];
      case UserRole.cashier:
        return const [
          _Destination.pos,
          _Destination.sales,
          _Destination.customers,
        ];
      case UserRole.inventoryManager:
        return const [_Destination.products, _Destination.inventory];
      case null:
        return const [];
    }
  }

  void _select(_Destination key) {
    if (!_items.containsKey(key)) return;
    setState(() => _selected = key);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected ?? _Destination.dashboard;
    final current = _items[selected] ?? _items[_Destination.dashboard];
    final bottomItems = _bottomKeys
        .where((key) => _items.containsKey(key))
        .map((key) => _items[key]!)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            currentLabel: current?.label ?? 'Dashboard',
            drawerItems: _drawerKeys
                .where((key) => _items.containsKey(key))
                .map((key) => _items[key]!)
                .toList(),
            onSelected: _select,
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 104 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: current?.builder() ??
                      const Center(child: Text('No modules available')),
                ),
                if (bottomItems.isNotEmpty)
                  _FloatingBottomNav(
                    items: bottomItems,
                    selected: selected,
                    onSelected: _select,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentLabel,
    required this.drawerItems,
    required this.onSelected,
  });

  final String currentLabel;
  final List<_NavItem> drawerItems;
  final ValueChanged<_Destination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            PopupMenuButton<_Destination>(
              tooltip: 'Modules',
              offset: const Offset(0, 48),
              onSelected: onSelected,
              itemBuilder: (_) => [
                PopupMenuItem<_Destination>(
                  enabled: false,
                  child: Text(
                    'Open module',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const PopupMenuDivider(),
                for (final item in drawerItems)
                  PopupMenuItem<_Destination>(
                    value: item.key,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.label)),
                      ],
                    ),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.chair_alt_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Rhonalyn's",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    currentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final _Destination selected;
  final ValueChanged<_Destination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = items.indexWhere((item) => item.key == selected);
    final safeIndex = index < 0 ? 0 : index;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => onSelected(items[i].key),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
