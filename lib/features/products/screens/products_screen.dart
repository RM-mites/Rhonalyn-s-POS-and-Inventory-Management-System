import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variant.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/catalog_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogProvider>().loadAll();
      context.read<SettingsProvider>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Products & Variants',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<CatalogProvider>().loadAll(),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [_ProductsTab(), _CategoriesTab()],
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    if (catalog.isLoading && catalog.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.error != null && catalog.products.isEmpty) {
      return _ErrorView(message: catalog.error!, onRetry: catalog.loadAll);
    }
    final filtered = catalog.products.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.category?.name.toLowerCase().contains(q) ?? false);
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
                    hintText: 'Search by name, SKU, or category',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openProductForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add product'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _ProductTile(product: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catName = product.category?.name ?? 'Uncategorized';
    return Card(
      elevation: 0,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: product.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            product.isMadeToOrder ? Icons.build_outlined : Icons.chair_outlined,
            color: product.isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$catName • ${product.sku} • ${formatPeso(product.basePrice)}'
          '${product.isMadeToOrder ? ' • Made to order' : ' • Stock: ${product.totalStock}'}'
          '${product.isActive ? '' : ' • Inactive'}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openProductForm(context, existing: product),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteProduct(context, product),
            ),
          ],
        ),
        children: [
          if (product.variants.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No variants yet.'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final v in product.variants)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${v.label} (${v.sku})'),
                      subtitle: Text(
                        [
                          if (v.size != null) 'Size: ${v.size}',
                          if (v.color != null) 'Color: ${v.color}',
                          if (v.material != null) 'Material: ${v.material}',
                        ].join(' • ').ifEmpty('No attributes'),
                      ),
                      trailing: Text(
                        '${formatPeso(v.price)}\n${v.trackStock ? 'Stock: ${v.stockQty}' : 'Untracked'}',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    if (catalog.isLoading && catalog.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Organize your furniture catalog by category.'),
              ),
              FilledButton.icon(
                onPressed: () => _openCategoryForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
              ),
            ],
          ),
        ),
        Expanded(
          child: catalog.categories.isEmpty
              ? const Center(child: Text('No categories yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: catalog.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = catalog.categories[i];
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(c.name),
                        subtitle: c.description == null || c.description!.isEmpty
                            ? null
                            : Text(c.description!),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openCategoryForm(context, existing: c),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _confirmDeleteCategory(context, c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}

Future<void> _openCategoryForm(BuildContext context,
    {Category? existing}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final formKey = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add category' : 'Edit category'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final err = await ctx.read<CatalogProvider>().saveCategory(
                  id: existing?.id,
                  name: nameCtrl.text,
                  description: descCtrl.text,
                );
            if (!ctx.mounted) return;
            if (err != null) {
              ScaffoldMessenger.of(ctx)
                  .showSnackBar(SnackBar(content: Text(err)));
              return;
            }
            Navigator.pop(ctx, true);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  descCtrl.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Category saved.')));
  }
}

Future<void> _confirmDeleteCategory(BuildContext context, Category c) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete category'),
      content: Text('Delete "${c.name}"? Products in it will become uncategorized.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final err = await context.read<CatalogProvider>().deleteCategory(c.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Category deleted.')));
}

Future<void> _confirmDeleteProduct(BuildContext context, Product p) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete product'),
      content: Text(
          'Delete "${p.name}" and all its variants? This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final err = await context.read<CatalogProvider>().deleteProduct(p.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(err ?? 'Product deleted.')));
}

Future<void> _openProductForm(BuildContext context, {Product? existing}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<CatalogProvider>(),
      child: _ProductFormDialog(existing: existing),
    ),
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Product saved.')));
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.existing});
  final Product? existing;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _desc;
  late final TextEditingController _basePrice;
  late final TextEditingController _lowStock;
  String? _categoryId;
  bool _madeToOrder = false;
  bool _active = true;
  bool _saving = false;
  late List<VariantDraft> _variants;
  final List<String> _deletedVariantIds = [];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _basePrice = TextEditingController(
        text: p != null ? p.basePrice.toStringAsFixed(2) : '');
    final defaultThreshold = context
            .read<SettingsProvider>()
            .settings
            ?.defaultLowStockThreshold ??
        5;
    _lowStock = TextEditingController(
      text: (p?.lowStockThreshold ?? defaultThreshold).toString(),
    );
    _categoryId = p?.categoryId;
    _madeToOrder = p?.isMadeToOrder ?? false;
    _active = p?.isActive ?? true;
    _variants = p?.variants.map(VariantDraft.fromVariant).toList() ?? [];
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _desc.dispose();
    _basePrice.dispose();
    _lowStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    for (var i = 0; i < _variants.length; i++) {
      final v = _variants[i];
      if (v.sku.trim().isEmpty || v.label.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Variant ${i + 1}: SKU and label are required.')));
        return;
      }
      if (v.price < 0 || v.stockQty < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Variant ${i + 1}: price/stock cannot be negative.')));
        return;
      }
    }
    setState(() => _saving = true);
    final err = await context.read<CatalogProvider>().saveProduct(
          id: widget.existing?.id,
          name: _name.text,
          sku: _sku.text,
          categoryId: _categoryId,
          description: _desc.text,
          basePrice: double.tryParse(_basePrice.text.trim()) ?? 0,
          isMadeToOrder: _madeToOrder,
          lowStockThreshold: int.tryParse(_lowStock.text.trim()) ?? 5,
          imageUrl: null,
          isActive: _active,
          variants: _variants,
          deletedVariantIds: _deletedVariantIds,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pop(context, true);
  }

  void _addVariant() async {
    final draft = VariantDraft(
      sku: '',
      label: '',
      price: double.tryParse(_basePrice.text.trim()) ?? 0,
      trackStock: !_madeToOrder,
    );
    final ok = await _editVariantDraft(context, draft, isNew: true);
    if (ok == true) setState(() => _variants.add(draft));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogProvider>().categories;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Product name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sku,
                        decoration: const InputDecoration(labelText: 'Base SKU'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('Uncategorized')),
                          for (final c in categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _basePrice,
                        decoration:
                            const InputDecoration(labelText: 'Base price (₱)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        validator: (v) => (double.tryParse(v?.trim() ?? '') == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lowStock,
                        decoration: const InputDecoration(
                            labelText: 'Low-stock threshold'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _madeToOrder,
                          onChanged: (v) => setState(() => _madeToOrder = v),
                        ),
                        const Text('Made to order'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                        ),
                        const Text('Active'),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text('Variants (${_variants.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: const Text('Add variant'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_variants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'Add at least one variant (size/color/material/SKU/price/stock).'),
                  )
                else
                  ..._variants.asMap().entries.map((e) {
                    final i = e.key;
                    final v = e.value;
                    return Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${v.label} (${v.sku})'),
                        subtitle: Text(
                          '${formatPeso(v.price)} • '
                          '${v.trackStock ? 'Stock: ${v.stockQty}' : 'Untracked'}'
                          '${v.isActive ? '' : ' • Inactive'}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final ok = await _editVariantDraft(context, v,
                                    isNew: false);
                                if (ok == true) setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() {
                                if (v.id != null) _deletedVariantIds.add(v.id!);
                                _variants.removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save product'),
        ),
      ],
    );
  }
}

Future<bool?> _editVariantDraft(BuildContext context, VariantDraft draft,
    {required bool isNew}) {
  final sku = TextEditingController(text: draft.sku);
  final label = TextEditingController(text: draft.label);
  final size = TextEditingController(text: draft.size ?? '');
  final color = TextEditingController(text: draft.color ?? '');
  final material = TextEditingController(text: draft.material ?? '');
  final price = TextEditingController(text: draft.price.toStringAsFixed(2));
  final stock = TextEditingController(text: draft.stockQty.toString());
  final threshold = TextEditingController(
      text: draft.lowStockThreshold?.toString() ?? '');
  bool trackStock = draft.trackStock;
  bool active = draft.isActive;
  final formKey = GlobalKey<FormState>();

  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(isNew ? 'Add variant' : 'Edit variant'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: label,
                        decoration:
                            const InputDecoration(labelText: 'Label (e.g. Walnut / Large)'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: sku,
                        decoration:
                            const InputDecoration(labelText: 'Variant SKU'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: size,
                        decoration:
                            const InputDecoration(labelText: 'Size (optional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: color,
                        decoration:
                            const InputDecoration(labelText: 'Color (optional)'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: material,
                    decoration:
                        const InputDecoration(labelText: 'Material (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        decoration:
                            const InputDecoration(labelText: 'Price (₱)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: stock,
                        decoration:
                            const InputDecoration(labelText: 'Stock qty'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: threshold,
                        decoration: const InputDecoration(
                            labelText: 'Low-stock override'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Switch(
                        value: trackStock,
                        onChanged: (v) => setD(() => trackStock = v)),
                    const Text('Track stock'),
                    const SizedBox(width: 16),
                    Switch(
                        value: active, onChanged: (v) => setD(() => active = v)),
                    const Text('Active'),
                  ]),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              draft.sku = sku.text.trim();
              draft.label = label.text.trim();
              draft.size = size.text.trim().isEmpty ? null : size.text.trim();
              draft.color = color.text.trim().isEmpty ? null : color.text.trim();
              draft.material =
                  material.text.trim().isEmpty ? null : material.text.trim();
              draft.price = double.tryParse(price.text.trim()) ?? 0;
              draft.stockQty = int.tryParse(stock.text.trim()) ?? 0;
              draft.lowStockThreshold = threshold.text.trim().isEmpty
                  ? null
                  : int.tryParse(threshold.text.trim());
              draft.trackStock = trackStock;
              draft.isActive = active;
              Navigator.pop(ctx, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
