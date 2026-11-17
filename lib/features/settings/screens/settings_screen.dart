import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/store_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SettingsProvider>();
      if (provider.settings == null) provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final settings = provider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Settings',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Store details used on receipts and store-wide defaults.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.load(),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading && settings == null
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null && settings == null
                  ? _ErrorView(
                      message: provider.error!,
                      onRetry: () => provider.load(),
                    )
                  : settings == null
                      ? const Center(child: Text('No settings available.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: _SettingsForm(initial: settings),
                        ),
        ),
      ],
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.initial});

  final StoreSettings initial;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeName;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  late final TextEditingController _footer;
  late final TextEditingController _threshold;

  @override
  void initState() {
    super.initState();
    _storeName = TextEditingController(text: widget.initial.storeName);
    _address = TextEditingController(text: widget.initial.address ?? '');
    _contact = TextEditingController(text: widget.initial.contact ?? '');
    _footer = TextEditingController(text: widget.initial.receiptFooter ?? '');
    _threshold = TextEditingController(
      text: widget.initial.defaultLowStockThreshold.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.initial, widget.initial)) return;
    _storeName.text = widget.initial.storeName;
    _address.text = widget.initial.address ?? '';
    _contact.text = widget.initial.contact ?? '';
    _footer.text = widget.initial.receiptFooter ?? '';
    _threshold.text = widget.initial.defaultLowStockThreshold.toString();
  }

  @override
  void dispose() {
    for (final c in [_storeName, _address, _contact, _footer, _threshold]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saving = context.watch<SettingsProvider>().isSaving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Store details',
            subtitle: 'Shown at the top of on-screen receipts.',
            child: Column(
              children: [
                TextFormField(
                  controller: _storeName,
                  decoration: const InputDecoration(
                    labelText: 'Store name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Store name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contact,
                  decoration: const InputDecoration(
                    labelText: 'Contact number / email',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Receipt footer',
            subtitle: 'Printed at the bottom of the on-screen receipt.',
            child: TextFormField(
              controller: _footer,
              decoration: const InputDecoration(
                labelText: 'Footer message',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Inventory defaults',
            subtitle: 'Applied to new products as their low-stock threshold.',
            child: SizedBox(
              width: 320,
              child: TextFormField(
                controller: _threshold,
                decoration: const InputDecoration(
                  labelText: 'Default low-stock threshold',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0) {
                    return 'Enter a threshold of 0 or higher';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Receipt preview',
            subtitle: 'How the store header and footer will appear.',
            child: _ReceiptPreview(
              storeName: _storeName.text,
              address: _address.text,
              contact: _contact.text,
              footer: _footer.text,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving...' : 'Save settings'),
              ),
              const SizedBox(width: 12),
              Text(
                'Only admins can change these settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = StoreSettings(
      storeName: _storeName.text,
      address: _address.text,
      contact: _contact.text,
      receiptFooter: _footer.text,
      defaultLowStockThreshold: int.parse(_threshold.text.trim()),
    );
    final err = await context.read<SettingsProvider>().save(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Store settings saved.')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({
    required this.storeName,
    required this.address,
    required this.contact,
    required this.footer,
  });

  final String storeName;
  final String address;
  final String contact;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = storeName.trim().isEmpty
        ? StoreSettings.defaults.storeName
        : storeName.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (contact.trim().isNotEmpty)
                    Text(contact.trim(), style: theme.textTheme.bodySmall),
                  if (address.trim().isNotEmpty)
                    Text(
                      address.trim(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(child: Text('Sample item')),
                Text(formatPeso(1250)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(child: Text('Quantity')),
                const Text('1'),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  formatPeso(1250),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              footer.trim().isEmpty
                  ? (StoreSettings.defaults.receiptFooter ?? '')
                  : footer.trim(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
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
