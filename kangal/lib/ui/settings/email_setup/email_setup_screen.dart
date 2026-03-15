import 'package:flutter/material.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:provider/provider.dart';

import 'email_setup_view_model.dart';

class EmailSetupScreen extends StatefulWidget {
  const EmailSetupScreen({super.key});

  @override
  State<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends State<EmailSetupScreen> {
  late final EmailSetupViewModel _viewModel;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _viewModel = EmailSetupViewModel(
      secureStorageService: context.read<SecureStorageService>(),
      emailImportRepository: context.read<EmailImportRepository>(),
    );
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.loadCredentials();
      _emailController.text = _viewModel.email;
      _passwordController.text = _viewModel.appPassword;
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Setup')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) => _viewModel.email = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'App Password'),
                  onChanged: (value) => _viewModel.appPassword = value,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _viewModel.isTestingConnection
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          _viewModel.email = _emailController.text.trim();
                          _viewModel.appPassword = _passwordController.text;
                          final ok = await _viewModel.testConnection();
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Connection successful'
                                    : (_viewModel.errorMessage ??
                                          'Connection failed'),
                              ),
                            ),
                          );
                        },
                  child: _viewModel.isTestingConnection
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _viewModel.isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          _viewModel.email = _emailController.text.trim();
                          _viewModel.appPassword = _passwordController.text;
                          final saved = await _viewModel.saveCredentials();
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'Credentials saved'
                                    : (_viewModel.errorMessage ??
                                          'Save failed'),
                              ),
                            ),
                          );
                        },
                  child: _viewModel.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Credentials?'),
                        content: const Text(
                          'This will remove saved email credentials.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true || !mounted) {
                      return;
                    }

                    await _viewModel.deleteCredentials();
                    _emailController.clear();
                    _passwordController.clear();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Credentials removed')),
                      );
                    }
                  },
                  child: const Text('Remove Credentials'),
                ),
                const SizedBox(height: 12),
                if (_viewModel.connectionTestResult != null)
                  Text(
                    _viewModel.connectionTestResult!
                        ? 'Connection test: Success'
                        : 'Connection test: Failed',
                  ),
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
