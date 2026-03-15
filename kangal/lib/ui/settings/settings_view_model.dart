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
  bool isSyncing = false;
  bool isAuthenticated = false;
  SyncResult? lastSyncResult;

  Future<void> loadSyncStatus() async {
    try {
      lastSyncTime = await _syncRepository.getLastSyncTime();
      hasUnsyncedChanges = await _syncRepository.hasUnsyncedChanges();
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> loadAuthStatus() async {
    try {
      isAuthenticated = await _supabaseAuthService.isAuthenticated();
      notifyListeners();
    } catch (_) {
      isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    isSyncing = true;
    notifyListeners();

    try {
      lastSyncResult = await _syncRepository.syncNow();
      lastSyncTime = await _syncRepository.getLastSyncTime();
      hasUnsyncedChanges = await _syncRepository.hasUnsyncedChanges();
    } catch (error) {
      lastSyncResult = SyncResult(
        uploaded: 0,
        downloaded: 0,
        conflictsResolved: 0,
        success: false,
        errorMessage: error.toString(),
      );
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
