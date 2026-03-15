import 'package:flutter/foundation.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/services/secure_storage_service.dart';

class EmailSetupViewModel extends ChangeNotifier {
  EmailSetupViewModel({
    required SecureStorageService secureStorageService,
    required EmailImportRepository emailImportRepository,
  }) : _secureStorageService = secureStorageService,
       _emailImportRepository = emailImportRepository;

  final SecureStorageService _secureStorageService;
  final EmailImportRepository _emailImportRepository;

  String email = '';
  String appPassword = '';
  bool isTestingConnection = false;
  bool? connectionTestResult;
  bool isSaving = false;
  String? errorMessage;

  Future<void> loadCredentials() async {
    final credentials = await _secureStorageService.getEmailCredentials();
    if (credentials == null) {
      return;
    }

    email = credentials.email;
    appPassword = credentials.appPassword;
    notifyListeners();
  }

  Future<bool> testConnection() async {
    if (email.trim().isEmpty || appPassword.isEmpty) {
      errorMessage = 'Please enter both email and app password.';
      connectionTestResult = false;
      notifyListeners();
      return false;
    }

    errorMessage = null;
    isTestingConnection = true;
    notifyListeners();

    try {
      await _secureStorageService.saveEmailCredentials(
        email.trim(),
        appPassword,
      );
      final success = await _emailImportRepository.testConnection();
      connectionTestResult = success;
      if (!success) {
        errorMessage = 'Could not connect to Gmail. Check your credentials.';
      }
      return success;
    } catch (error) {
      connectionTestResult = false;
      errorMessage = 'Could not connect to Gmail. Check your credentials.';
      return false;
    } finally {
      isTestingConnection = false;
      notifyListeners();
    }
  }

  Future<bool> saveCredentials() async {
    if (email.trim().isEmpty || appPassword.isEmpty) {
      errorMessage = 'Please enter both email and app password.';
      notifyListeners();
      return false;
    }

    errorMessage = null;
    isSaving = true;
    notifyListeners();

    try {
      await _secureStorageService.saveEmailCredentials(
        email.trim(),
        appPassword,
      );
      return true;
    } catch (error) {
      errorMessage = 'Failed to save credentials: $error';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteCredentials() async {
    await _secureStorageService.deleteEmailCredentials();
    email = '';
    appPassword = '';
    connectionTestResult = null;
    errorMessage = null;
    notifyListeners();
  }
}
