import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_log_table.dart';

part 'sync_log_dao.g.dart';

@DriftAccessor(tables: [SyncLogTable])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(AppDatabase db) : super(db);

  Future<SyncLog?> getLastSync(String tableName) => (select(syncLogTable)..where((s) => s.tableName.equals(tableName))).getSingleOrNull();

  Future<int> upsertSyncLog(Insertable<SyncLog> companion) => into(syncLogTable).insertOnConflictUpdate(companion);
}