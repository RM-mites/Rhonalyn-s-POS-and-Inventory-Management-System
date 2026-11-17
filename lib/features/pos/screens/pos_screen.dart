import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/models/sale_record.dart';
import '../../customers/providers/customers_provider.dart';
import '../../products/providers/catalog_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/cart_provider.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _query = '';
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogProvider>().loadAll();
      context.read<CustomersProvider>().loadCustomers();
      context.read<SettingsProvider>().load(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    final products = catalog.products.where((p) {
      if (!p.isActive) return false;
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.variants.any((v) =>
              v.label.toLowerCase().contains(q) ||
              v.sku.toLowerCase().contains(q));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Point of Sale',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh products',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<CatalogProvider>().loadAll();
                  context.read<CustomersProvider>().loadCustomers();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _buildCatalog(context, catalog, products)),
                const SizedBox(width: 16),
                SizedBox(width: 420, child: _CartPanel(cart: cart)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalog(BuildContext context, CatalogProvider catalog, List<Product> products) {
    if (catalog.isLoading && catalog.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.error != null && catalog.products.isEmpty) {
      return _ErrorView(message: catalog.error!, onRetry: catalog.loadAll);
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search products or variants',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: () => _openCustomItemDialog(context),
              icon: const Icon(Icons.edit_note),
              label: const Text('Custom / MTO'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
              ),
              for (final c in catalog.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No products found.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240, mainAxisExtent: 170,
                    crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductCard(product: products[i]),
                ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeVariants = product.variants.where((v) => v.isActive).toList();
    final stockLabel = product.isMadeToOrder
        ? 'Made to order'
        : activeVariants.any((v) => v.trackStock)
            ? 'Stock: ${product.totalStock}'
            : 'Untracked';
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: activeVariants.isEmpty
            ? () => _openCustomItemDialog(context, product: product)
            : () => _pickVariant(context, product, activeVariants),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(product.isMadeToOrder ? Icons.design_services_outlined : Icons.chair_outlined,
                    color: theme.colorScheme.primary),
                const Spacer(),
                if (product.isMadeToOrder)
                  const Chip(label: Text('MTO'), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
              ]),
              const SizedBox(height: 8),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(product.category?.name ?? 'Uncategorized',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(formatPeso(product.basePrice),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$stockLabel • ${activeVariants.length} variant(s)',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(children: [
              Expanded(child: Text('Current sale (${cart.itemCount} items)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (!cart.isEmpty) TextButton(onPressed: cart.clear, child: const Text('Clear')),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(24),
                    child: Text('Tap a product to add it, or create a custom / made-to-order line.',
                        textAlign: TextAlign.center)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CartLine(index: i),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row('Subtotal', formatPeso(cart.subtotal), theme),
              const SizedBox(height: 4),
              _row('Discount', '- ${formatPeso(cart.discount)}', theme),
              const SizedBox(height: 6),
              _row('Total', formatPeso(cart.total), theme, bold: true),
              const SizedBox(height: 12),
              _CustomerSelector(cart: cart),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: cart.isEmpty || cart.isCheckingOut ? null : () => _openCheckoutDialog(context),
                  icon: cart.isCheckingOut
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.payments_outlined),
                  label: Text(cart.isCheckingOut ? 'Processing...' : 'Checkout'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ThemeData theme, {bool bold = false}) {
    final style = bold ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) : theme.textTheme.bodyMedium;
    return Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]);
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (index >= cart.items.length) return const SizedBox.shrink();
    final item = cart.items[index];
    final theme = Theme.of(context);
    final specSummary = _specSummary(item.customSpecs);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (specSummary.isNotEmpty)
              Text(specSummary, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if ((item.notes ?? '').isNotEmpty) Text('Note: ${item.notes}', style: theme.textTheme.bodySmall),
            if (item.madeToOrder != null)
              Text('MTO • Deposit ${formatPeso(item.madeToOrder!.depositAmount)} • Balance ${formatPeso(item.madeToOrder!.balanceDue)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
          ])),
          IconButton(tooltip: 'Remove', icon: const Icon(Icons.close, size: 18),
              onPressed: () => cart.removeAt(index), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrement(index), visualDensity: VisualDensity.compact),
          Text('${item.quantity}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.increment(index), visualDensity: VisualDensity.compact),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatPeso(item.unitPrice), style: theme.textTheme.bodySmall),
            Text(formatPeso(item.lineTotal), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]),
    );
  }

  String _specSummary(Map<String, dynamic> specs) {
    final parts = <String>[];
    for (final k in ['dimensions', 'material', 'fabric', 'color', 'finish']) {
      final v = specs[k];
      if (v != null && v.toString().trim().isNotEmpty) parts.add('${k[0].toUpperCase()}${k.substring(1)}: $v');
    }
    return parts.join(' • ');
  }
}

class _CustomerSelector extends StatelessWidget {
  const _CustomerSelector({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomersProvider>().customers.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final selected = cart.customer;
    return DropdownButtonFormField<String?>(
      initialValue: selected?.id,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Customer (optional)', prefixIcon: Icon(Icons.person_outline)),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Walk-in customer')),
        for (final c in customers)
          DropdownMenuItem<String?>(
            value: c.id,
            child: Text(c.name + (c.balance > 0 ? ' • bal ${formatPeso(c.balance)}' : ''), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id == null) { cart.setCustomer(null); return; }
        final c = customers.where((x) => x.id == id).toList();
        cart.setCustomer(c.isEmpty ? null : c.first);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool silent}) onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
      ]));
}

Future<void> _pickVariant(BuildContext context, Product product, List<ProductVariant> variants) async {
  if (variants.length == 1) {
    final err = context.read<CartProvider>().addVariant(product, variants.first);
    if (err != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    return;
  }
  final chosen = await showDialog<ProductVariant>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text('Select variant — ${product.name}'),
      children: [for (final v in variants) SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, v),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text([if ((v.size ?? '').isNotEmpty) v.size!, if ((v.color ?? '').isNotEmpty) v.color!, if ((v.material ?? '').isNotEmpty) v.material!, v.trackStock ? 'Stock: ${v.stockQty}' : 'Untracked'].join(' • '),
                style: Theme.of(ctx).textTheme.bodySmall),
          ])),
          Text(formatPeso(v.price), style: const TextStyle(fontWeight: FontWeight.w700)),
        ])),
      )],
    ),
  );
  if (chosen == null || !context.mounted) return;
  final err = context.read<CartProvider>().addVariant(product, chosen);
  if (err != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
}

Future<void> _openCustomItemDialog(BuildContext context, {Product? product}) async {
  final item = await showDialog<CartItem>(context: context, builder: (_) => _CustomItemDialog(product: product));
  if (item == null || !context.mounted) return;
  context.read<CartProvider>().addCustomItem(item);
}

class _CustomItemDialog extends StatefulWidget {
  const _CustomItemDialog({this.product});
  final Product? product;
  @override
  State<_CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<_CustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _desc, _qty, _price;
  final _dims = TextEditingController(), _material = TextEditingController(), _fabric = TextEditingController();
  final _color = TextEditingController(), _finish = TextEditingController(), _notes = TextEditingController();
  bool _isMto = false;
  final _deposit = TextEditingController(text: '0');
  DateTime? _dueDate;
  final _deliveryAddr = TextEditingController(), _deliveryNotes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _desc = TextEditingController(text: p?.name ?? '');
    _qty = TextEditingController(text: '1');
    _price = TextEditingController(text: p != null && p.basePrice > 0 ? p.basePrice.toStringAsFixed(2) : '');
    _isMto = p?.isMadeToOrder ?? false;
  }

  @override
  void dispose() {
    for (final c in [_desc,_qty,_price,_dims,_material,_fabric,_color,_finish,_notes,_deposit,_deliveryAddr,_deliveryNotes]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom / made-to-order item'),
      content: Form(key: _formKey, child: SizedBox(width: 560, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Item description'),
              validator: (v) => (v==null||v.trim().isEmpty)?'Required':null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _qty, decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v){ final n=int.tryParse(v?.trim()??''); if(n==null||n<=0) return 'Enter qty > 0'; return null;})),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Unit price (₱)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v){ final n=double.tryParse(v?.trim()??''); if(n==null||n<0) return 'Invalid price'; return null;})),
          ]),
          const SizedBox(height: 16),
          Text('Custom specifications', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _dims, decoration: const InputDecoration(labelText: 'Dimensions'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _material, decoration: const InputDecoration(labelText: 'Material'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _fabric, decoration: const InputDecoration(labelText: 'Fabric'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _color, decoration: const InputDecoration(labelText: 'Color'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _finish, decoration: const InputDecoration(labelText: 'Finish')),
          const SizedBox(height: 12),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Line notes (optional)'), maxLines: 2),
          const SizedBox(height: 8),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Made-to-order job'),
              subtitle: const Text('Capture deposit, balance, due date, and delivery details'),
              value: _isMto, onChanged: (v) => setState(() => _isMto = v)),
          if (_isMto) ...[
            TextField(controller: _deposit, decoration: const InputDecoration(labelText: 'Deposit amount (₱)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context,
                      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365*3)));
                  if (picked != null) setState(() => _dueDate = picked);
                },
                icon: const Icon(Icons.event), label: Text(_dueDate == null ? 'Due date' : formatDate(_dueDate!)),
              )),
              if (_dueDate != null) IconButton(tooltip: 'Clear date', icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _deliveryAddr, decoration: const InputDecoration(labelText: 'Delivery address'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: _deliveryNotes, decoration: const InputDecoration(labelText: 'Delivery notes'), maxLines: 2),
          ],
        ],
      )))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add to cart')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(_qty.text.trim());
    final price = double.parse(_price.text.trim());
    final specs = <String, dynamic>{};
    void put(String k, TextEditingController c){ final v=c.text.trim(); if(v.isNotEmpty) specs[k]=v; }
    put('dimensions', _dims); put('material', _material); put('fabric', _fabric); put('color', _color); put('finish', _finish);

    MadeToOrderInfo? mto;
    if (_isMto) {
      final target = price * qty;
      final deposit = double.tryParse(_deposit.text.trim()) ?? 0;
      if (deposit < 0 || deposit > target) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deposit must be between 0 and ${formatPeso(target)}.')));
        return;
      }
      mto = MadeToOrderInfo(targetPrice: target, depositAmount: deposit, dueDate: _dueDate,
          deliveryAddress: _deliveryAddr.text.trim().isEmpty ? null : _deliveryAddr.text.trim(),
          deliveryNotes: _deliveryNotes.text.trim().isEmpty ? null : _deliveryNotes.text.trim(), specs: specs);
    }
    Navigator.pop(context, CartItem(productId: widget.product?.id, variantId: null, description: _desc.text.trim(),
        quantity: qty, unitPrice: price, isCustom: true, trackStock: false, customSpecs: specs,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(), madeToOrder: mto));
  }
}

Future<void> _openCheckoutDialog(BuildContext context) async {
  final cart = context.read<CartProvider>();
  final discountCtrl = TextEditingController(text: cart.discount.toStringAsFixed(2));
  final paidCtrl = TextEditingController(text: cart.total.toStringAsFixed(2));
  final notesCtrl = TextEditingController();
  String method = 'cash';
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  final sale = await showDialog<SaleRecord>(
    context: context, barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
      final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;
      final total = (cart.subtotal - discount).clamp(0, double.infinity);
      final paid = double.tryParse(paidCtrl.text.trim()) ?? 0;
      final change = method == 'credit' ? 0.0 : (paid - total).clamp(0, double.infinity);
      return AlertDialog(
        title: const Text('Checkout'),
        content: Form(key: formKey, child: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _summaryRow('Items', '${cart.itemCount}'),
            _summaryRow('Subtotal', formatPeso(cart.subtotal)),
            const SizedBox(height: 8),
            TextFormField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Discount (₱)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], onChanged: (_) => setD(() {}),
                validator: (v){ final d=double.tryParse(v?.trim()??''); if(d==null||d<0) return 'Invalid discount'; if(d>cart.subtotal) return 'Cannot exceed subtotal'; return null;}),
            const SizedBox(height: 8),
            _summaryRow('Total', formatPeso(total), bold: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: method, decoration: const InputDecoration(labelText: 'Payment method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
                DropdownMenuItem(value: 'credit', child: Text('Store credit (utang)')),
              ],
              onChanged: (v) => setD(() { method = v ?? 'cash'; if (method != 'credit') paidCtrl.text = total.toStringAsFixed(2); }),
            ),
            if (method == 'credit') ...[
              const SizedBox(height: 8),
              Text(cart.customer == null ? 'Select a customer in the cart for credit sales.' : 'Charging to: ${cart.customer!.name}',
                  style: TextStyle(color: cart.customer == null ? Theme.of(ctx).colorScheme.error : Theme.of(ctx).colorScheme.primary)),
            ],
            if (method != 'credit') ...[
              const SizedBox(height: 12),
              TextFormField(controller: paidCtrl, decoration: const InputDecoration(labelText: 'Amount paid (₱)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], onChanged: (_) => setD(() {}),
                  validator: (v){ final p=double.tryParse(v?.trim()??''); if(p==null||p<0) return 'Invalid amount'; if(p+0.001<total) return 'Less than total'; return null;}),
              const SizedBox(height: 8), _summaryRow('Change', formatPeso(change)),
            ],
            const SizedBox(height: 12),
            TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Sale notes (optional)'), maxLines: 2),
          ],
        )))),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: saving ? null : () async {
            if (!formKey.currentState!.validate()) return;
            if (method == 'credit' && cart.customer == null) return;
            setD(() => saving = true);
            final d = double.tryParse(discountCtrl.text.trim()) ?? 0;
            cart.setDiscount(d);
            final result = await context.read<CartProvider>().checkout(
              paymentMethod: method,
              amountPaid: method == 'credit' ? null : double.tryParse(paidCtrl.text.trim()),
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            );
            if (!ctx.mounted) return;
            setD(() => saving = false);
            if (result.error != null) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(result.error!))); return; }
            Navigator.pop(ctx, result.sale);
          }, child: saving ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Confirm sale')),
        ],
      );
    }),
  );
  for (final c in [discountCtrl, paidCtrl, notesCtrl]) { c.dispose(); }
  if (sale != null && context.mounted) await _showReceiptDialog(context, sale);
}

Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null))),
    Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
  ]),
);

Future<void> _showReceiptDialog(BuildContext context, SaleRecord sale) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final settings = ctx.watch<SettingsProvider>().settings;
      final storeName = settings?.storeName.trim() ?? '';
      final displayName =
          storeName.isEmpty ? "Rhonalyn's Furniture" : storeName;
      final footer = settings?.receiptFooter?.trim() ?? '';
      return AlertDialog(
        title: const Text('Sale completed'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Column(children: [
              Icon(Icons.check_circle, size: 48, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(height: 8),
              Text(displayName, textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if ((settings?.contact ?? '').isNotEmpty)
                Text(settings!.contact!, style: Theme.of(ctx).textTheme.bodySmall),
              if ((settings?.address ?? '').isNotEmpty)
                Text(settings!.address!, textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 4), Text('Receipt ${sale.receiptNo}'),
              if (sale.createdAt != null) Text(formatDateTime(sale.createdAt!), style: Theme.of(ctx).textTheme.bodySmall),
            ])),
            const Divider(height: 24),
            _summaryRow('Payment', _paymentLabel(sale.paymentMethod)),
            _summaryRow('Subtotal', formatPeso(sale.subtotal)),
            _summaryRow('Discount', '- ${formatPeso(sale.discount)}'),
            const Divider(height: 16),
            _summaryRow('Total', formatPeso(sale.total), bold: true),
            if (sale.paymentMethod != 'credit') ...[
              _summaryRow('Amount paid', formatPeso(sale.amountPaid)),
              _summaryRow('Change', formatPeso(sale.changeDue)),
            ] else const Padding(padding: EdgeInsets.only(top: 4), child: Text('Charged to store credit (utang).')),
            if ((sale.notes ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text('Notes: ${sale.notes}')],
            const SizedBox(height: 12),
            if (footer.isNotEmpty)
              Text(footer, textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  )),
          ],
        ))),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      );
    },
  );
}

String _paymentLabel(String m) {
  switch (m) { case 'gcash': return 'GCash'; case 'bank_transfer': return 'Bank transfer'; case 'credit': return 'Store credit'; default: return 'Cash'; }
}
