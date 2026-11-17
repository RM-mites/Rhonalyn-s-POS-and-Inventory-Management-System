import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/credit_payment.dart';
import '../../../data/models/customer.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomersProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final customers = provider.customers.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q);
    }).toList();

    Customer? selected;
    if (_selectedId != null) {
      for (final c in customers) {
        if (c.id == _selectedId) {
          selected = c;
          break;
        }
      }
      selected ??= provider.customers
          .where((c) => c.id == _selectedId)
          .cast<Customer?>()
          .firstWhere((_) => true, orElse: () => null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Customers & Credit',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadCustomers(),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openCustomerForm(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add customer'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildList(context, provider, customers),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: selected == null
                      ? _EmptyDetail(
                          message: customers.isEmpty
                              ? 'Add a customer to track store credit.'
                              : 'Select a customer to view details and payments.',
                        )
                      : _CustomerDetail(
                          key: ValueKey(selected.id),
                          customer: selected,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    CustomersProvider provider,
    List<Customer> customers,
  ) {
    if (provider.isLoading && provider.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.customers.isEmpty) {
      return _ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadCustomers(),
      );
    }
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search name, phone, or email',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: customers.isEmpty
              ? const Center(child: Text('No customers found.'))
              : ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = customers[i];
                    final selected = c.id == _selectedId;
                    return _CustomerTile(
                      customer: c,
                      selected: selected,
                      onTap: () {
                        setState(() => _selectedId = c.id);
                        context.read<CustomersProvider>().loadPayments(c.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  final Customer customer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBalance = customer.balance > 0;
    return Card(
      elevation: 0,
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: hasBalance
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            hasBalance ? Icons.account_balance_wallet : Icons.person_outline,
            color: hasBalance
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if ((customer.phone ?? '').isNotEmpty) customer.phone!,
            if ((customer.email ?? '').isNotEmpty) customer.email!,
            if (!customer.isActive) 'Inactive',
          ].where((e) => e.isNotEmpty).join(' • ').ifEmpty('No contact info'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPeso(customer.balance),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: hasBalance ? theme.colorScheme.error : null,
              ),
            ),
            Text('balance', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  const _CustomerDetail({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final theme = Theme.of(context);
    final limitText = customer.creditLimit <= 0
        ? 'No limit'
        : formatPeso(customer.creditLimit);
    final available = customer.creditLimit <= 0
        ? '—'
        : formatPeso(
            (customer.creditLimit - customer.balance)
                .clamp(0, customer.creditLimit),
          );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((customer.phone ?? '').isNotEmpty)
                            customer.phone!,
                          if ((customer.email ?? '').isNotEmpty)
                            customer.email!,
                        ].join(' • ').ifEmpty('No contact details'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((customer.address ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(customer.address!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _openCustomerForm(context, existing: customer),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, customer),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(label: 'Balance (Utang)', value: formatPeso(customer.balance), highlight: customer.balance > 0),
                _StatCard(label: 'Credit limit', value: limitText),
                _StatCard(label: 'Available credit', value: available),
                _StatCard(label: 'Status', value: customer.isActive ? 'Active' : 'Inactive'),
              ],
            ),
            if ((customer.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notes: ${customer.notes}', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment history',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: customer.balance > 0
                      ? () => _openPaymentDialog(context, customer)
                      : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record payment'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildPayments(context, provider, customer.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayments(
    BuildContext context,
    CustomersProvider provider,
    String customerId,
  ) {
    if (provider.isLoadingPayments && provider.paymentsCustomerId == customerId) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.paymentsError != null && provider.paymentsCustomerId == customerId) {
      return _ErrorView(
        message: provider.paymentsError!,
        onRetry: () => provider.loadPayments(customerId),
      );
    }
    if (provider.paymentsCustomerId != customerId) {
      return const Center(child: Text('Loading payments...'));
    }
    final payments = provider.payments;
    if (payments.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
    }
    return ListView.separated(
      itemCount: payments.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _PaymentTile(payment: payments[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final CreditPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      _methodLabel(payment.method),
      if ((payment.notes ?? '').isNotEmpty) payment.notes!,
      formatDateTime(payment.createdAt),
    ].join(' • ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.south_west, size: 18, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(formatPeso(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }

  static String _methodLabel(String m) {
    switch (m) {
      case 'gcash':
        return 'GCash';
      case 'bank_transfer':
        return 'Bank transfer';
      case 'cash':
      default:
        return 'Cash';
    }
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
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

Future<void> _openCustomerForm(BuildContext context, {Customer? existing}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final limit = TextEditingController(
      text: existing != null ? existing.creditLimit.toStringAsFixed(2) : '0.00');
  final notes = TextEditingController(text: existing?.notes ?? '');
  bool active = existing?.isActive ?? true;
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(existing == null ? 'Add customer' : 'Edit customer'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: limit,
                    decoration: const InputDecoration(
                      labelText: 'Credit limit (₱, 0 = no limit)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n < 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notes,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setD(() => active = v),
                  ),
                ],
              ),
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
                    setD(() => saving = true);
                    final err = await ctx.read<CustomersProvider>().saveCustomer(
                          id: existing?.id,
                          name: name.text,
                          phone: phone.text,
                          email: email.text,
                          address: address.text,
                          creditLimit: double.tryParse(limit.text.trim()) ?? 0,
                          notes: notes.text,
                          isActive: active,
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
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );

  for (final c in [name, phone, email, address, limit, notes]) {
    c.dispose();
  }
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Customer saved.')));
  }
}

Future<void> _confirmDelete(BuildContext context, Customer c) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete customer'),
      content: Text('Delete "${c.name}"? This cannot be undone.'),
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
  final err = await context.read<CustomersProvider>().deleteCustomer(c.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(err ?? 'Customer deleted.')));
}

Future<void> _openPaymentDialog(BuildContext context, Customer c) async {
  final amount = TextEditingController(
      text: c.balance > 0 ? c.balance.toStringAsFixed(2) : '');
  final notes = TextEditingController();
  String method = 'cash';
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Record payment'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${c.name}',
                    style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Outstanding balance: ${formatPeso(c.balance)}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  decoration: const InputDecoration(labelText: 'Amount (₱)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter an amount greater than 0';
                    if (n > c.balance + 0.001) return 'Cannot exceed outstanding balance';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                    DropdownMenuItem(
                        value: 'bank_transfer', child: Text('Bank transfer')),
                  ],
                  onChanged: (v) => setD(() => method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
                    setD(() => saving = true);
                    final err = await ctx.read<CustomersProvider>().recordPayment(
                          customerId: c.id,
                          amount: double.parse(amount.text.trim()),
                          method: method,
                          notes: notes.text,
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
                : const Text('Save payment'),
          ),
        ],
      ),
    ),
  );

  amount.dispose();
  notes.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Payment recorded.')));
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
