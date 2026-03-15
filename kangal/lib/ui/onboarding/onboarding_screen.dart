import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:provider/provider.dart';

import 'onboarding_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.viewModel});

  final OnboardingViewModel? viewModel;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late final OnboardingViewModel _viewModel;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _viewModel =
        widget.viewModel ??
        OnboardingViewModel(
          smsPermissionService: context.read<SmsPermissionService>(),
          smsImportRepository: context.read<SmsImportRepository>(),
          secureStorageService: context.read<SecureStorageService>(),
          emailImportRepository: context.read<EmailImportRepository>(),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    _viewModel.setCurrentStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Kangal')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPage(
                      title: 'Welcome',
                      description:
                          'Track your spending automatically from HBL and NayaPay.',
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 96),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => _goToStep(1),
                          child: const Text('Get Started'),
                        ),
                      ],
                    ),
                    _buildPage(
                      title: 'HBL SMS',
                      description:
                          'Grant SMS permission to read HBL transaction alerts automatically.',
                      children: [
                        FilledButton(
                          onPressed: _viewModel.isImporting
                              ? null
                              : () async {
                                  await _viewModel.requestSmsPermission();
                                },
                          child: _viewModel.isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Grant SMS Permission'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _viewModel.smsPermissionGranted
                              ? 'Permission granted'
                              : 'Permission not granted',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _viewModel.skipStep();
                                _goToStep(2);
                              },
                              child: const Text('Skip'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => _goToStep(2),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildPage(
                      title: 'NayaPay Email',
                      description:
                          'Use a Gmail App Password.\n1) Google Account > Security > 2-Step Verification > App Passwords\n2) Generate password\n3) Enter below',
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'App Password',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _viewModel.isImporting
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final success = await _viewModel
                                      .saveEmailCredentials(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Email connected successfully'
                                            : (_viewModel.errorMessage ??
                                                  'Connection failed'),
                                      ),
                                    ),
                                  );
                                },
                          child: _viewModel.isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _viewModel.emailConfigured
                              ? 'Email configured'
                              : 'Email not configured',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _viewModel.skipStep();
                                _goToStep(3);
                              },
                              child: const Text('Skip'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => _goToStep(3),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildPage(
                      title: 'Cloud Backup',
                      description:
                          'Create a Supabase account to enable cloud sync and backups.',
                      children: [
                        FilledButton.tonal(
                          onPressed: () async {
                            await context.push('/settings/auth');
                            _viewModel.setSupabaseConfigured(true);
                          },
                          child: const Text('Sign Up'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _viewModel.supabaseConfigured
                              ? 'Supabase configured'
                              : 'Optional step',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _viewModel.skipStep();
                                _goToStep(4);
                              },
                              child: const Text('Skip'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => _goToStep(4),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildPage(
                      title: 'Done',
                      description:
                          '${_viewModel.importedTransactionCount} transactions imported!',
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 96,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () async {
                            await _viewModel.completeOnboarding();
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                          child: const Text('Go to Dashboard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isActive = _viewModel.currentStep == index;
                    return Container(
                      width: isActive ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
