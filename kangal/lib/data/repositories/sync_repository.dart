import 'package:kangal/data/models/sync_result.dart';

abstract class SyncRepository {
  Future<SyncResult> syncNow();
  Future<DateTime?> getLastSyncTime();
  Future<bool> hasUnsyncedChanges();
  Future<int> getUnsyncedChangesCount();
}
