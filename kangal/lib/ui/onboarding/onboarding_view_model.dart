import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel extends ChangeNotifier {
  int currentStep = 0;
  bool smsPermissionGranted = false;
  bool emailConfigured = false;
  bool supabaseConfigured = false;
  int importedTransactionCount = 0;
  bool isImporting = false;

  Future<void> requestSmsPermission() async {
    // Simulate SMS permission request logic
    smsPermissionGranted = true;
    notifyListeners();

    if (smsPermissionGranted) {
      // Simulate importing SMS transactions
      importedTransactionCount = 10; // Example count
      notifyListeners();
    }
  }

  Future<void> saveEmailCredentials(String email, String password) async {
    // Simulate saving email credentials
    emailConfigured = true;
    notifyListeners();

    if (emailConfigured) {
      // Simulate importing emails
      importedTransactionCount += 5; // Example count
      notifyListeners();
    }
  }

  void skipStep() {
    currentStep++;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    notifyListeners();
  }
}
