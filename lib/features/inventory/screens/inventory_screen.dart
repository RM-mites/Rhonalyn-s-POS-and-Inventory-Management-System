import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/inventory_item.dart';
import '../../../data/models/stock_movement.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inv = context.read<InventoryProvider>();
      inv.loadAll();
      inv.loadMovements();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Inventory',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (inv.lowStockCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: Text('${inv.lowStockCount} low stock'),
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                  ),
                ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  inv.loadAll();
                  inv.loadMovements(variantId: inv.movementVariantFilter);
                },
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Stock levels'),
            Tab(text: 'Movement history'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [_StockTab(), _MovementsTab()],
          ),
        ),
      ],
    );
  }
}

class _StockTab extends StatefulWidget {
  const _StockTab();

  @override
  State<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<_StockTab> {
  String _query = '';
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    if (inv.isLoading && inv.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (inv.error != null && inv.items.isEmpty) {
      return _ErrorView(message: inv.error!, onRetry: () => inv.loadAll());
    }
    final filtered = inv.items.where((i) {
      if (_lowOnly && !i.isLowStock) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return i.productName.toLowerCase().contains(q) ||
          i.variantLabel.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search product or variant',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Low stock only'),
                selected: _lowOnly,
                onSelected: (v) => setState(() => _lowOnly = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No inventory items found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _InventoryTile(item: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = item.isLowStock;
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: low
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
          child: Icon(
            low ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            color: low
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text('${item.productName} — ${item.variantLabel}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item.trackStock ? 'Threshold: ${item.threshold}' : 'Stock not tracked'}'
          '${item.isActive ? '' : ' • Inactive'}',
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.trackStock ? '${item.stockQty}' : '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: low ? theme.colorScheme.error : null,
                  ),
                ),
                Text('in stock', style: theme.textTheme.labelSmall),
              ],
            ),
            FilledButton.tonalIcon(
              onPressed: item.trackStock
                  ? () => _openAdjustDialog(context, item)
                  : null,
              icon: const Icon(Icons.tune),
              label: const Text('Adjust'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementsTab extends StatelessWidget {
  const _MovementsTab();

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    if (inv.isLoadingMovements && inv.movements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (inv.movementsError != null && inv.movements.isEmpty) {
      return _ErrorView(
        message: inv.movementsError!,
        onRetry: () async =>
            inv.loadMovements(variantId: inv.movementVariantFilter),
      );
    }

    String filterLabel = 'All variants';
    if (inv.movementVariantFilter != null) {
      final match = inv.items
          .where((i) => i.variantId == inv.movementVariantFilter)
          .toList();
      if (match.isNotEmpty) {
        filterLabel = '${match.first.productName} — ${match.first.variantLabel}';
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text('Showing: $filterLabel')),
              if (inv.movementVariantFilter != null)
                TextButton.icon(
                  onPressed: () => inv.loadMovements(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filter'),
                ),
            ],
          ),
        ),
        Expanded(
          child: inv.movements.isEmpty
              ? const Center(child: Text('No stock movements yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: inv.movements.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _MovementTile(movement: inv.movements[i]),
                ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = movement.quantityChange > 0;
    final qtyText =
        '${positive ? '+' : ''}${movement.quantityChange}';
    final title = movement.productName != null
        ? '${movement.productName} — ${movement.variantLabel ?? ''}'
        : (movement.variantLabel ?? movement.variantId);
    final subtitleParts = <String>[
      _typeLabel(movement.movementType),
      if (movement.notes != null && movement.notes!.isNotEmpty) movement.notes!,
      formatDateTime(movement.createdAt),
    ];
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: positive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        child: Icon(
          positive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
          color: positive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onErrorContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: Text(
        qtyText,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: positive ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'Sale';
      case 'restock':
        return 'Restock';
      case 'void':
        return 'Void (restored)';
      case 'initial':
        return 'Initial stock';
      case 'adjustment':
      default:
        return 'Adjustment';
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Future<void> _openAdjustDialog(BuildContext context, InventoryItem item) async {
  String mode = 'restock'; // restock | deduct | set
  final qtyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Adjust stock'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.productName} — ${item.variantLabel}',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text('Current stock: ${item.stockQty}'),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'restock', label: Text('Restock (+)')),
                    ButtonSegment(value: 'deduct', label: Text('Deduct (-)')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => setD(() => mode = s.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyCtrl,
                  decoration: InputDecoration(
                    labelText: mode == 'restock'
                        ? 'Quantity to add'
                        : 'Quantity to remove',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a quantity greater than 0';
                    if (mode == 'deduct' && n > item.stockQty) {
                      return 'Cannot deduct more than current stock (${item.stockQty})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason / notes',
                    hintText: 'e.g. Supplier delivery, damaged item',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final qty = int.parse(qtyCtrl.text.trim());
                    final delta = mode == 'restock' ? qty : -qty;
                    final movementType = mode == 'restock' ? 'restock' : 'adjustment';
                    setD(() => saving = true);
                    final err = await ctx.read<InventoryProvider>().adjustStock(
                          variantId: item.variantId,
                          quantityChange: delta,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                          movementType: movementType,
                        );
                    if (!ctx.mounted) return;
                    setD(() => saving = false);
                    if (err != null) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
            child: saving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save adjustment'),
          ),
        ],
      ),
    ),
  );

  qtyCtrl.dispose();
  notesCtrl.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Stock updated.')));
  }
}
