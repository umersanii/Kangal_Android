import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_log_table.dart';
import '../../models/sync_log_model.dart';

part 'sync_log_dao.g.dart';

@DriftAccessor(tables: [SyncLogTable])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  Future<SyncLogModel?> getLastSync(String tableName) async {
    final row = await (select(
      syncLogTable,
    )..where((s) => s.syncTableName.equals(tableName))).getSingleOrNull();

    if (row == null) return null;

    return SyncLogModel(
      id: row.id,
      tableName: row.syncTableName,
      lastSyncedAt: row.lastSyncedAt,
      status: row.status,
    );
  }

  Future<int> upsertSyncLog(SyncLogModel syncLog) {
    return into(syncLogTable).insertOnConflictUpdate(
      SyncLogTableCompanion(
        id: Value(syncLog.id),
        syncTableName: Value(syncLog.tableName),
        lastSyncedAt: Value(syncLog.lastSyncedAt),
        status: Value(syncLog.status),
      ),
    );
  }
}
