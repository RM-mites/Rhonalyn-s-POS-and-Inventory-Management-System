import 'package:flutter/material.dart';

import '../../core/config/env.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 28),
                if (error != null) _buildSetup(context) else _buildReady(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Finish setup', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Complete these steps once, then restart the app.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const _Step(
          number: 1,
          title: 'Create a Supabase project',
          body: 'Use a region close to you (Singapore works well for the '
              'Philippines).',
        ),
        const _Step(
          number: 2,
          title: 'Run the database migrations',
          body: 'In the Supabase SQL Editor, run the files in '
              'supabase/migrations in order: 0001_schema.sql, '
              '0002_functions.sql, 0003_rls.sql, then 0004_seed.sql.',
        ),
        const _Step(
          number: 3,
          title: 'Create your first admin account',
          body: 'Enable Email auth, sign up once, then set that profile row\'s '
              'role to "admin" in the profiles table.',
        ),
        const _Step(
          number: 4,
          title: 'Add your credentials',
          body: 'Copy .env.example to .env and fill in SUPABASE_URL and '
              'SUPABASE_ANON_KEY from Project Settings > API.',
        ),
        const _Step(
          number: 5,
          title: 'Restart the app',
          body: 'Run flutter run -d windows again.',
        ),
        const SizedBox(height: 16),
        Text(
          'The full walkthrough lives in supabase/README.md.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context) {
    final theme = Theme.of(context);
    final host = _safeProjectHost();
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Supabase connected', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Project: $host',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Phase 0 is complete. The database schema, security rules, and '
              'app bootstrap are in place. Sign-in and the role-based '
              'dashboard arrive in Phase 1.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _safeProjectHost() {
    try {
      return Env.projectHost;
    } catch (_) {
      return 'configured project';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.chair_alt_rounded,
            color: theme.colorScheme.onPrimaryContainer,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rhonalyn's POS & Inventory",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Point of sale and stock management for a furniture business',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
