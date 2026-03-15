import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:kangal/ui/onboarding/onboarding_screen.dart';
import 'package:kangal/ui/onboarding/onboarding_view_model.dart';

class _FakeSmsPermissionService extends SmsPermissionService {
  _FakeSmsPermissionService({required this.granted});

  bool granted;

  @override
  Future<bool> requestSmsPermission() async => granted;

  @override
  Future<bool> isSmsPermissionGranted() async => granted;
}

class _FakeSmsImportRepository implements SmsImportRepository {
  _FakeSmsImportRepository({required this.importCount});

  int importCount;
  int? lastDaysBack;

  @override
  Future<int> importHistoricalSms({int? daysBack}) async {
    lastDaysBack = daysBack;
    return importCount;
  }

  @override
  void startRealtimeListener() {}
}

class _FakeSecureStorageService extends SecureStorageService {
  @override
  Future<void> saveEmailCredentials(String email, String appPassword) async {}
}

class _FakeEmailImportRepository implements EmailImportRepository {
  _FakeEmailImportRepository({
    required this.connectionResult,
    required this.importCount,
  });

  bool connectionResult;
  int importCount;

  @override
  Future<int> importEmails() async => importCount;

  @override
  Future<bool> testConnection() async => connectionResult;
}

void main() {
  testWidgets('selected SMS range is forwarded to import', (tester) async {
    final smsRepository = _FakeSmsImportRepository(importCount: 2);
    final viewModel = OnboardingViewModel(
      smsPermissionService: _FakeSmsPermissionService(granted: true),
      smsImportRepository: smsRepository,
      secureStorageService: _FakeSecureStorageService(),
      emailImportRepository: _FakeEmailImportRepository(
        connectionResult: true,
        importCount: 3,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(viewModel: viewModel)),
    );

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last 90 days'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant SMS Permission'));
    await tester.pumpAndSettle();

    expect(smsRepository.lastDaysBack, 90);
  });

  testWidgets('onboarding renders 5 steps and skip buttons navigate', (
    tester,
  ) async {
    final viewModel = OnboardingViewModel(
      smsPermissionService: _FakeSmsPermissionService(granted: true),
      smsImportRepository: _FakeSmsImportRepository(importCount: 2),
      secureStorageService: _FakeSecureStorageService(),
      emailImportRepository: _FakeEmailImportRepository(
        connectionResult: true,
        importCount: 3,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(viewModel: viewModel)),
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('HBL SMS'), findsOneWidget);

    await tester.tap(find.text('Skip').first);
    await tester.pumpAndSettle();
    expect(find.text('NayaPay Email'), findsOneWidget);

    await tester.tap(find.text('Skip').first);
    await tester.pumpAndSettle();
    expect(find.text('Cloud Backup'), findsOneWidget);

    await tester.tap(find.text('Skip').first);
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('transactions imported!'), findsOneWidget);
  });
}
