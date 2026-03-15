import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/repositories/sync_repository.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:kangal/ui/settings/settings_view_model.dart';

class _FakeSyncRepository implements SyncRepository {
  SyncResult syncResult = const SyncResult(
    uploaded: 0,
    downloaded: 0,
    conflictsResolved: 0,
    success: true,
  );
  DateTime? lastSyncTime;
  bool unsyncedChanges = false;
  bool throwOnSync = false;

  @override
  Future<DateTime?> getLastSyncTime() async {
    return lastSyncTime;
  }

  @override
  Future<bool> hasUnsyncedChanges() async {
    return unsyncedChanges;
  }

  @override
  Future<SyncResult> syncNow() async {
    if (throwOnSync) {
      throw Exception('Sync failed');
    }
    return syncResult;
  }
}

class _FakeSupabaseAuthService extends SupabaseAuthService {
  _FakeSupabaseAuthService(this.authenticated);

  bool authenticated;

  @override
  Future<bool> isAuthenticated() async {
    return authenticated;
  }
}

void main() {
  late _FakeSyncRepository syncRepository;
  late _FakeSupabaseAuthService authService;
  late SettingsViewModel viewModel;

  setUp(() {
    syncRepository = _FakeSyncRepository();
    authService = _FakeSupabaseAuthService(false);
    viewModel = SettingsViewModel(
      syncRepository: syncRepository,
      supabaseAuthService: authService,
    );
  });

  test('loadSyncStatus updates lastSyncTime and unsynced flag', () async {
    final expectedSyncTime = DateTime(2026, 3, 15, 9, 0);
    syncRepository.lastSyncTime = expectedSyncTime;
    syncRepository.unsyncedChanges = true;

    await viewModel.loadSyncStatus();

    expect(viewModel.lastSyncTime, expectedSyncTime);
    expect(viewModel.hasUnsyncedChanges, isTrue);
  });

  test('loadAuthStatus updates authentication state', () async {
    authService.authenticated = true;

    await viewModel.loadAuthStatus();

    expect(viewModel.isAuthenticated, isTrue);
  });

  test('syncNow sets sync result and refreshes status fields', () async {
    final expectedSyncTime = DateTime(2026, 3, 15, 10, 30);
    syncRepository.syncResult = const SyncResult(
      uploaded: 4,
      downloaded: 2,
      conflictsResolved: 1,
      success: true,
    );
    syncRepository.lastSyncTime = expectedSyncTime;
    syncRepository.unsyncedChanges = false;

    await viewModel.syncNow();

    expect(viewModel.isSyncing, isFalse);
    expect(viewModel.lastSyncResult, isNotNull);
    expect(viewModel.lastSyncResult!.success, isTrue);
    expect(viewModel.lastSyncResult!.uploaded, 4);
    expect(viewModel.lastSyncTime, expectedSyncTime);
    expect(viewModel.hasUnsyncedChanges, isFalse);
  });

  test('syncNow handles sync errors and returns failed result', () async {
    syncRepository.throwOnSync = true;

    await viewModel.syncNow();

    expect(viewModel.isSyncing, isFalse);
    expect(viewModel.lastSyncResult, isNotNull);
    expect(viewModel.lastSyncResult!.success, isFalse);
    expect(viewModel.lastSyncResult!.errorMessage, contains('Sync failed'));
  });
}
