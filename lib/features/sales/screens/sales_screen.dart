import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/sale_record.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sales_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _query = '';
  String _status = 'all'; // all, completed, voided
  String _method = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SalesProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final sales = provider.sales.where((s) {
      if (_status != 'all' && s.status != _status) return false;
      if (_method != 'all' && s.paymentMethod != _method) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.receiptNo.toLowerCase().contains(q) ||
          (s.customerName ?? '').toLowerCase().contains(q) ||
          (s.cashierName ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(children: [
            Expanded(child: Text('Sales History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => provider.loadSales()),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(flex: 5, child: _buildList(context, provider, sales)),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: _DetailPane()),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, SalesProvider provider, List<SaleRecord> sales) {
    if (provider.isLoading && provider.sales.isEmpty) return const Center(child: CircularProgressIndicator());
    if (provider.error != null && provider.sales.isEmpty) {
      return _ErrorView(message: provider.error!, onRetry: () => provider.loadSales());
    }
    return Column(children: [
      TextField(
        decoration: const InputDecoration(hintText: 'Search receipt, customer, or cashier', prefixIcon: Icon(Icons.search)),
        onChanged: (v) => setState(() => _query = v.trim()),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status', isDense: true),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All statuses')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'voided', child: Text('Voided')),
          ],
          onChanged: (v) => setState(() => _status = v ?? 'all'),
        )),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(
          initialValue: _method,
          decoration: const InputDecoration(labelText: 'Payment', isDense: true),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All methods')),
            DropdownMenuItem(value: 'cash', child: Text('Cash')),
            DropdownMenuItem(value: 'gcash', child: Text('GCash')),
            DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
            DropdownMenuItem(value: 'credit', child: Text('Store credit')),
          ],
          onChanged: (v) => setState(() => _method = v ?? 'all'),
        )),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: sales.isEmpty
            ? const Center(child: Text('No sales found.'))
            : ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _SaleTile(sale: sales[i]),
              ),
      ),
    ]);
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});
  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final selected = provider.selectedId == sale.id;
    final theme = Theme.of(context);
    final voided = sale.isVoided;
    final subtitleParts = <String>[
      if (sale.createdAt != null) formatDateTime(sale.createdAt!),
      sale.customerName?.isNotEmpty == true ? sale.customerName! : 'Walk-in',
      _paymentLabel(sale.paymentMethod),
    ];
    return Card(
      elevation: 0,
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: () => context.read<SalesProvider>().loadDetail(sale.id),
        leading: CircleAvatar(
          backgroundColor: voided ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
          child: Icon(voided ? Icons.block : Icons.receipt_long,
              color: voided ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer),
        ),
        title: Row(children: [
          Expanded(child: Text(sale.receiptNo, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (voided) _StatusChip(label: 'VOIDED', color: theme.colorScheme.error),
        ]),
        subtitle: Text(subtitleParts.join(' • ')),
        trailing: Text(formatPeso(sale.total),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: voided ? TextDecoration.lineThrough : null,
              color: voided ? theme.colorScheme.onSurfaceVariant : null,
            )),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class _DetailPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final auth = context.watch<AuthProvider>();
    final id = provider.selectedId;
    if (id == null) {
      return const _EmptyDetail(message: 'Select a sale to view details and receipt.');
    }
    if (provider.isLoadingDetail && provider.selectedDetail?.sale.id != id) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.detailError != null) {
      return _ErrorView(message: provider.detailError!, onRetry: () => provider.loadDetail(id));
    }
    final detail = provider.selectedDetail;
    if (detail == null) return const _EmptyDetail(message: 'No details available.');
    final sale = detail.sale;
    final theme = Theme.of(context);
    final isAdmin = auth.profile?.role.dbValue == 'admin';

    return Card(elevation: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 8), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(sale.receiptNo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (sale.isVoided) _StatusChip(label: 'VOIDED', color: theme.colorScheme.error)
            else _StatusChip(label: 'COMPLETED', color: Colors.green.shade700),
          ]),
          const SizedBox(height: 2),
          Text([if (sale.createdAt != null) formatDateTime(sale.createdAt!),
                'Cashier: ${sale.cashierName ?? '—'}',
                'Customer: ${sale.customerName ?? 'Walk-in'}'].join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
        if (isAdmin && !sale.isVoided)
          FilledButton.tonalIcon(
            onPressed: () => _confirmVoid(context, sale),
            icon: const Icon(Icons.block),
            label: const Text('Void sale'),
            style: FilledButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
      ])),
      const Divider(height: 1),
      Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
        if (sale.isVoided) Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(10)),
          child: Text('This sale was voided${sale.voidedAt != null ? ' on ${formatDateTime(sale.voidedAt!)}' : ''}. Stock and store credit (if any) were reversed.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer)),
        ),
        Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (detail.items.isEmpty) const Text('No line items recorded.')
        else for (final item in detail.items) _LineTile(item: item),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _row('Subtotal', formatPeso(sale.subtotal)),
        _row('Discount', '- ${formatPeso(sale.discount)}'),
        const SizedBox(height: 4),
        _row('Total', formatPeso(sale.total), bold: true),
        const SizedBox(height: 8),
        _row('Payment', _paymentLabel(sale.paymentMethod)),
        if (sale.paymentMethod != 'credit') ...[
          _row('Amount paid', formatPeso(sale.amountPaid)),
          _row('Change', formatPeso(sale.changeDue)),
        ] else const Padding(padding: EdgeInsets.only(top: 4), child: Text('Charged to store credit (utang).')),
        if ((sale.notes ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text('Notes: ${sale.notes}')],
        if (detail.jobs.isNotEmpty) ...[
          const SizedBox(height: 16), const Divider(), const SizedBox(height: 8),
          Text('Made-to-order jobs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final job in detail.jobs) _JobTile(job: job),
        ],
      ])),
    ]));
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null))),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
    ]),
  );
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.item});
  final SaleLineDetail item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (item.productName != null && item.productName != item.description) item.productName!,
      if ((item.variantLabel ?? '').isNotEmpty) item.variantLabel!,
      '${item.quantity} × ${formatPeso(item.unitPrice)}',
      if (item.isCustom) 'Custom',
      if ((item.notes ?? '').isNotEmpty) item.notes!,
    ].join(' • ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle.isNotEmpty) Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (item.customSpecs != null && item.customSpecs!.isNotEmpty)
            Text(_specs(item.customSpecs!), style: theme.textTheme.bodySmall),
        ])),
        const SizedBox(width: 12),
        Text(formatPeso(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _specs(Map<String, dynamic> m) {
    final parts = <String>[];
    for (final e in m.entries) {
      final v = e.value?.toString().trim();
      if (v != null && v.isNotEmpty) parts.add('${e.key}: $v');
    }
    return parts.join(' • ');
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});
  final MadeToOrderJobDetail job;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv('Target price', formatPeso(job.targetPrice)),
        _kv('Deposit', formatPeso(job.depositAmount)),
        _kv('Balance due', formatPeso(job.balanceDue)),
        if (job.dueDate != null) _kv('Due date', formatDate(job.dueDate!)),
        if ((job.deliveryAddress ?? '').isNotEmpty) _kv('Delivery', job.deliveryAddress!),
        if ((job.deliveryNotes ?? '').isNotEmpty) _kv('Delivery notes', job.deliveryNotes!),
      ]),
    );
  }
  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))), Expanded(child: Text(v))]));
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center))));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message; final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(message, textAlign: TextAlign.center), const SizedBox(height: 12),
    FilledButton(onPressed: onRetry, child: const Text('Retry')),
  ]));
}

Future<void> _confirmVoid(BuildContext context, SaleRecord sale) async {
  final reason = TextEditingController();
  bool saving = false;
  final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
    title: const Text('Void sale'),
    content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Void ${sale.receiptNo}? This will restore tracked stock and reverse store credit (if charged). This cannot be undone.'),
      const SizedBox(height: 12),
      TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason (optional)'), maxLines: 2),
    ])),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      FilledButton(onPressed: saving ? null : () async {
        setD(() => saving = true);
        final err = await ctx.read<SalesProvider>().voidSale(sale.id, reason: reason.text);
        if (!ctx.mounted) return;
        setD(() => saving = false);
        if (err != null) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err))); return; }
        Navigator.pop(ctx, true);
      }, child: saving ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Void sale')),
    ],
  )));
  reason.dispose();
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale voided.')));
  }
}

String _paymentLabel(String m) {
  switch (m) { case 'gcash': return 'GCash'; case 'bank_transfer': return 'Bank transfer'; case 'credit': return 'Store credit'; default: return 'Cash'; }
}
