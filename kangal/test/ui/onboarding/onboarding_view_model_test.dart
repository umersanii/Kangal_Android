import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:kangal/ui/onboarding/onboarding_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Future<int> importHistoricalSms() async => importCount;

  @override
  void startRealtimeListener() {}
}

class _FakeSecureStorageService extends SecureStorageService {
  ({String email, String appPassword})? credentials;

  @override
  Future<void> saveEmailCredentials(String email, String appPassword) async {
    credentials = (email: email, appPassword: appPassword);
  }

  @override
  Future<({String email, String appPassword})?> getEmailCredentials() async {
    return credentials;
  }

  @override
  Future<void> deleteEmailCredentials() async {
    credentials = null;
  }
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
  late _FakeSmsPermissionService smsPermissionService;
  late _FakeSmsImportRepository smsImportRepository;
  late _FakeSecureStorageService secureStorageService;
  late _FakeEmailImportRepository emailImportRepository;
  late OnboardingViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    smsPermissionService = _FakeSmsPermissionService(granted: true);
    smsImportRepository = _FakeSmsImportRepository(importCount: 3);
    secureStorageService = _FakeSecureStorageService();
    emailImportRepository = _FakeEmailImportRepository(
      connectionResult: true,
      importCount: 4,
    );

    viewModel = OnboardingViewModel(
      smsPermissionService: smsPermissionService,
      smsImportRepository: smsImportRepository,
      secureStorageService: secureStorageService,
      emailImportRepository: emailImportRepository,
    );
  });

  test('skipStep advances current step', () {
    expect(viewModel.currentStep, 0);

    viewModel.skipStep();
    expect(viewModel.currentStep, 1);

    viewModel.skipStep();
    expect(viewModel.currentStep, 2);
  });

  test('requestSmsPermission imports when granted', () async {
    await viewModel.requestSmsPermission();

    expect(viewModel.smsPermissionGranted, isTrue);
    expect(viewModel.importedTransactionCount, 3);
  });

  test('saveEmailCredentials imports emails and adds to count', () async {
    final success = await viewModel.saveEmailCredentials(
      'user@example.com',
      'app-password',
    );

    expect(success, isTrue);
    expect(viewModel.emailConfigured, isTrue);
    expect(viewModel.importedTransactionCount, 4);
    expect(secureStorageService.credentials, isNotNull);
    expect(secureStorageService.credentials!.email, 'user@example.com');
  });

  test(
    'completeOnboarding sets onboarding_complete in SharedPreferences',
    () async {
      await viewModel.completeOnboarding();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    },
  );
}
