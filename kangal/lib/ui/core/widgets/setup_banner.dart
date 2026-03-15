import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:provider/provider.dart';

class SetupBanner extends StatefulWidget {
  const SetupBanner({super.key});

  @override
  State<SetupBanner> createState() => _SetupBannerState();
}

class _SetupBannerState extends State<SetupBanner> {
  bool _isLoading = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVisibility();
    });
  }

  Future<void> _loadVisibility() async {
    try {
      final smsPermissionService = context.read<SmsPermissionService>();
      final secureStorageService = context.read<SecureStorageService>();

      final smsGranted = await smsPermissionService.isSmsPermissionGranted();
      final emailConfigured = await secureStorageService.hasEmailCredentials();

      if (!mounted) {
        return;
      }

      setState(() {
        _showBanner = !smsGranted && !emailConfigured;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showBanner = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_showBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Set up your banks to start tracking automatically'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => context.go('/settings'),
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }
}
