import 'package:flutter/material.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required SmsPermissionService smsPermissionService,
    required SmsImportRepository smsImportRepository,
    required SecureStorageService secureStorageService,
    required EmailImportRepository emailImportRepository,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _smsPermissionService = smsPermissionService,
       _smsImportRepository = smsImportRepository,
       _secureStorageService = secureStorageService,
       _emailImportRepository = emailImportRepository,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  final SmsPermissionService _smsPermissionService;
  final SmsImportRepository _smsImportRepository;
  final SecureStorageService _secureStorageService;
  final EmailImportRepository _emailImportRepository;
  final Future<SharedPreferences> Function() _preferencesProvider;

  int currentStep = 0;
  bool smsPermissionGranted = false;
  bool emailConfigured = false;
  bool supabaseConfigured = false;
  int importedTransactionCount = 0;
  bool isImporting = false;
  String? errorMessage;

  Future<void> requestSmsPermission() async {
    errorMessage = null;
    smsPermissionGranted = await _smsPermissionService.requestSmsPermission();
    if (!smsPermissionGranted) {
      notifyListeners();
      return;
    }

    isImporting = true;
    notifyListeners();

    try {
      final imported = await _smsImportRepository.importHistoricalSms();
      importedTransactionCount += imported;
    } catch (error) {
      errorMessage = 'Failed to import SMS transactions: $error';
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<bool> saveEmailCredentials(String email, String password) async {
    errorMessage = null;
    isImporting = true;
    notifyListeners();

    try {
      await _secureStorageService.saveEmailCredentials(email, password);
      final canConnect = await _emailImportRepository.testConnection();

      if (!canConnect) {
        emailConfigured = false;
        errorMessage = 'Could not connect to Gmail. Check your credentials.';
        return false;
      }

      emailConfigured = true;
      final imported = await _emailImportRepository.importEmails();
      importedTransactionCount += imported;
      return true;
    } catch (error) {
      emailConfigured = false;
      errorMessage = 'Failed to set up email: $error';
      return false;
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  void skipStep() {
    currentStep = (currentStep + 1).clamp(0, 4);
    notifyListeners();
  }

  void setCurrentStep(int step) {
    currentStep = step.clamp(0, 4);
    notifyListeners();
  }

  void setSupabaseConfigured(bool configured) {
    supabaseConfigured = configured;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await _preferencesProvider();
    await prefs.setBool('onboarding_complete', true);
  }
}
