import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_role.dart';
import '../auth/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final theme = Theme.of(context);
    if (profile == null) return const SizedBox.shrink();

    final tiles = _tilesForRole(profile.role);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '$greeting, ${profile.displayName}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Signed in as ${profile.role.label}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: 260,
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tile.icon, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          tile.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tile.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<_DashTile> _tilesForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          _DashTile(Icons.point_of_sale, 'Point of Sale',
              'Process furniture sales and custom orders.'),
          _DashTile(Icons.inventory_2_outlined, 'Inventory',
              'Track stock levels and adjustments.'),
          _DashTile(Icons.people_outline, 'Customers',
              'Manage customers and store credit.'),
          _DashTile(Icons.bar_chart_outlined, 'Reports',
              'Review sales and performance analytics.'),
        ];
      case UserRole.cashier:
        return const [
          _DashTile(Icons.point_of_sale, 'Point of Sale',
              'Process sales and issue on-screen receipts.'),
          _DashTile(Icons.receipt_long_outlined, 'Sales History',
              'Review today’s and past transactions.'),
          _DashTile(Icons.people_outline, 'Customers',
              'Look up customers and record credit payments.'),
        ];
      case UserRole.inventoryManager:
        return const [
          _DashTile(Icons.chair_outlined, 'Products',
              'Maintain the furniture catalog and variants.'),
          _DashTile(Icons.inventory_2_outlined, 'Inventory',
              'Adjust stock and review movement history.'),
        ];
    }
  }
}

class _DashTile {
  const _DashTile(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}
