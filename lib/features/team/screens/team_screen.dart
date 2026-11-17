import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TeamProvider>().loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeamProvider>();
    final theme = Theme.of(context);
    final members = provider.members.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.displayName.toLowerCase().contains(q) ||
          m.role.label.toLowerCase().contains(q) ||
          (m.isActive ? 'active' : 'inactive').contains(q);
    }).toList();

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
                      'Team & Roles',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${provider.members.length} account(s) • '
                      '${provider.activeAdminCount} active admin(s)',
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
                onPressed: () => provider.loadMembers(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Staff accounts are created in Supabase Authentication. '
                      'New accounts appear here automatically as Cashier. '
                      'Admins can change roles and activation status; '
                      'deactivated accounts are signed out on their next login.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name, role, or status',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildList(context, provider, members),
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
    TeamProvider provider,
    List<Profile> members,
  ) {
    if (provider.isLoading && provider.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.members.isEmpty) {
      return _ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadMembers(),
      );
    }
    if (members.isEmpty) {
      return const Center(child: Text('No team members found.'));
    }
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _MemberTile(member: members[i]),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Profile member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';
    final roleColor = _roleColor(theme, member.role);
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: () => _openMemberEditor(context, member),
        leading: CircleAvatar(
          backgroundColor: member.isActive
              ? roleColor.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: member.isActive
                  ? roleColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!member.isActive) ...[
              const SizedBox(width: 8),
              _Tag(
                label: 'INACTIVE',
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            member.role.label,
            if (member.createdAt != null)
              'joined ${formatDate(member.createdAt!)}',
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleChip(role: member.role, color: roleColor),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Edit member',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openMemberEditor(context, member),
            ),
          ],
        ),
      ),
    );
  }

  static Color _roleColor(ThemeData theme, UserRole role) {
    switch (role) {
      case UserRole.admin:
        return theme.colorScheme.primary;
      case UserRole.cashier:
        return const Color(0xFF5B8DEF);
      case UserRole.inventoryManager:
        return const Color(0xFF34B27B);
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.color});

  final UserRole role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Tag(label: role.label.toUpperCase(), color: color);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
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

Future<void> _openMemberEditor(BuildContext context, Profile member) async {
  final provider = context.read<TeamProvider>();
  final currentId = context.read<AuthProvider>().profile?.id;
  final isSelf = member.id == currentId;
  final isLastActiveAdmin = member.role == UserRole.admin &&
      member.isActive &&
      provider.activeAdminCount <= 1;
  final lockAccess = isSelf || isLastActiveAdmin;

  final nameCtrl = TextEditingController(text: member.fullName ?? '');
  var role = member.role;
  var isActive = member.isActive;
  final formKey = GlobalKey<FormState>();
  var saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Edit team member'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the member name'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [
                    for (final value in UserRole.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: lockAccess
                      ? null
                      : (v) => setD(() => role = v ?? member.role),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active account'),
                  subtitle: Text(
                    isActive
                        ? 'Can sign in and use permitted modules.'
                        : 'Cannot sign in until reactivated.',
                  ),
                  value: isActive,
                  onChanged:
                      lockAccess ? null : (v) => setD(() => isActive = v),
                ),
                if (lockAccess)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isSelf
                          ? 'You cannot change your own role or deactivate your own account.'
                          : 'At least one active admin is required.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
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
                    final err = await ctx.read<TeamProvider>().saveMember(
                          member: member,
                          fullName: nameCtrl.text,
                          role: role,
                          isActive: isActive,
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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    ),
  );

  nameCtrl.dispose();
  if (saved == true && context.mounted) {
    if (isSelf) await context.read<AuthProvider>().refreshProfile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Team member updated.')));
  }
}
