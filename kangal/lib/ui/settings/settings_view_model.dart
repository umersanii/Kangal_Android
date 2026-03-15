import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/repositories/sync_repository.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SyncRepository _syncRepository;
  final SupabaseAuthService _supabaseAuthService;

  SettingsViewModel({
    required SyncRepository syncRepository,
    required SupabaseAuthService supabaseAuthService,
  }) : _syncRepository = syncRepository,
       _supabaseAuthService = supabaseAuthService;

  DateTime? lastSyncTime;
  bool hasUnsyncedChanges = false;
  int unsyncedChangesCount = 0;
  bool isSyncing = false;
  bool isAuthenticated = false;
  String? authenticatedEmail;
  SyncResult? lastSyncResult;
  String? errorMessage;

  Future<void> loadSyncStatus() async {
    errorMessage = null;
    try {
      lastSyncTime = await _syncRepository.getLastSyncTime();
      unsyncedChangesCount = await _syncRepository.getUnsyncedChangesCount();
      hasUnsyncedChanges = unsyncedChangesCount > 0;
      notifyListeners();
    } catch (_) {
      errorMessage = 'Sync failed. Will retry automatically.';
      notifyListeners();
    }
  }

  Future<void> loadAuthStatus() async {
    errorMessage = null;
    try {
      isAuthenticated = await _supabaseAuthService.isAuthenticated();
      authenticatedEmail = _supabaseAuthService.getCurrentUserEmail();
      notifyListeners();
    } catch (_) {
      isAuthenticated = false;
      authenticatedEmail = null;
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    errorMessage = null;
    isSyncing = true;
    notifyListeners();

    try {
      lastSyncResult = await _syncRepository.syncNow();
      lastSyncTime = await _syncRepository.getLastSyncTime();
      unsyncedChangesCount = await _syncRepository.getUnsyncedChangesCount();
      hasUnsyncedChanges = unsyncedChangesCount > 0;
    } catch (error) {
      errorMessage = 'Sync failed. Will retry automatically.';
      lastSyncResult = SyncResult(
        uploaded: 0,
        downloaded: 0,
        conflictsResolved: 0,
        success: false,
        errorMessage: 'Sync failed. Will retry automatically.',
      );
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
