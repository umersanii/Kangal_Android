import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/repositories/sync_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';

import 'settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _viewModel;
  late final SmsPermissionService _smsPermissionService;
  late final SecureStorageService _secureStorageService;
  bool _isLoadingDataSources = true;
  bool _isSmsPermissionGranted = false;
  bool _isEmailConfigured = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      syncRepository: context.read<SyncRepository>(),
      supabaseAuthService: context.read<SupabaseAuthService>(),
    );
    _smsPermissionService = context.read<SmsPermissionService>();
    _secureStorageService = context.read<SecureStorageService>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadStatuses();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    await _viewModel.loadAuthStatus();
    await _viewModel.loadSyncStatus();

    final smsGranted = await _smsPermissionService.isSmsPermissionGranted();
    final emailConfigured = await _secureStorageService.hasEmailCredentials();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSmsPermissionGranted = smsGranted;
      _isEmailConfigured = emailConfigured;
      _isLoadingDataSources = false;
    });
  }

  Future<void> _handleSyncNow() async {
    await _viewModel.syncNow();

    if (!mounted) {
      return;
    }

    final result = _viewModel.lastSyncResult;
    if (result == null) {
      return;
    }

    final message = result.success
        ? 'Sync complete: Uploaded ${result.uploaded}, Downloaded ${result.downloaded}, Conflicts ${result.conflictsResolved}'
        : 'Sync failed: ${result.errorMessage ?? 'Unknown error'}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final viewModel = _viewModel;
          final accountStatus = viewModel.isAuthenticated
              ? (viewModel.authenticatedEmail ?? 'Signed in')
              : 'Not signed in';
          final syncTime = viewModel.lastSyncTime;
          final formattedSyncTime = syncTime == null
              ? 'Never'
              : DateFormat('dd MMM yyyy, hh:mm a').format(syncTime);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionTitle('Account'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Supabase Account'),
                  subtitle: Text(accountStatus),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      await context.push('/settings/auth');
                      if (mounted) {
                        await _loadStatuses();
                      }
                    },
                    child: const Text('Sign Up / Sign In'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Sync'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Sync: $formattedSyncTime'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: viewModel.isSyncing
                                ? null
                                : _handleSyncNow,
                            icon: viewModel.isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                              viewModel.isSyncing ? 'Syncing...' : 'Sync Now',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            avatar: const Icon(Icons.pending_actions, size: 18),
                            label: Text(
                              '${viewModel.unsyncedChangesCount} unsynced',
                            ),
                          ),
                        ],
                      ),
                      if (viewModel.lastSyncResult != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          viewModel.lastSyncResult!.success
                              ? 'Last Result: Uploaded ${viewModel.lastSyncResult!.uploaded}, Downloaded ${viewModel.lastSyncResult!.downloaded}, Conflicts ${viewModel.lastSyncResult!.conflictsResolved}'
                              : 'Last Result: ${viewModel.lastSyncResult!.errorMessage ?? 'Failed'}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Data Sources'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sms_outlined),
                      title: const Text('SMS Setup'),
                      subtitle: Text(
                        _isLoadingDataSources
                            ? 'Checking...'
                            : 'Permission granted: ${_isSmsPermissionGranted ? 'Yes' : 'No'}',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          await context
                              .read<SmsPermissionService>()
                              .requestSmsPermission();
                          if (mounted) {
                            await _loadStatuses();
                          }
                        },
                        child: const Text('Setup'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email Setup'),
                      subtitle: Text(
                        _isLoadingDataSources
                            ? 'Checking...'
                            : 'Credentials configured: ${_isEmailConfigured ? 'Yes' : 'No'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/settings/email');
                        if (mounted) {
                          await _loadStatuses();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Categories'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage Categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/categories'),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Auto-Rules'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.rule_outlined),
                  title: const Text('Manage Auto-Rules'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/rules'),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Setup'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Re-run Setup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/onboarding'),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('About'),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('Kangal v1.0'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
