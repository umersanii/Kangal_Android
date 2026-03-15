import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/database/daos/sync_log_dao.dart';
import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/sync_log_model.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/sync_repository_impl.dart';
import 'package:kangal/data/services/supabase_sync_service.dart';

class _FakeSupabaseSyncService extends SupabaseSyncService {
  _FakeSupabaseSyncService({
    required super.transactionsDao,
    required super.categoriesDao,
    required super.rulesDao,
    required super.syncLogDao,
    required super.remoteDataSource,
    required this.nextResult,
  });

  SyncResult nextResult;

  @override
  Future<SyncResult> syncAll() async {
    return nextResult;
  }
}

class _NoopRemoteDataSource implements SupabaseSyncRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAll(String table) async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchUpdated(
    String table, {
    DateTime? updatedAfter,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async => rows;
}

class _FakeSyncLogDao extends SyncLogDao {
  _FakeSyncLogDao(super.db);

  SyncLogModel? syncLog;

  @override
  Future<SyncLogModel?> getLastSync(String tableName) async {
    return syncLog;
  }
}

class _FakeTransactionsDao extends TransactionsDao {
  _FakeTransactionsDao(super.db);

  List<TransactionModel> transactions = [];

  @override
  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async {
    return transactions;
  }
}

TransactionModel _transaction({
  required int id,
  DateTime? syncedAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 3, 15, 10, 0);
  return TransactionModel(
    id: id,
    date: now,
    amount: -100,
    source: 'Cash',
    type: 'manual',
    transactionId: 'txn-$id',
    beneficiary: 'Test',
    syncedAt: syncedAt,
    updatedAt: updatedAt ?? now,
    createdAt: now,
  );
}

void main() {
  late AppDatabase db;
  late _FakeSyncLogDao syncLogDao;
  late _FakeTransactionsDao transactionsDao;
  late _FakeSupabaseSyncService syncService;
  late SyncRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(e: NativeDatabase.memory());
    syncLogDao = _FakeSyncLogDao(db);
    transactionsDao = _FakeTransactionsDao(db);

    syncService = _FakeSupabaseSyncService(
      transactionsDao: db.transactionsDao,
      categoriesDao: db.categoriesDao,
      rulesDao: db.rulesDao,
      syncLogDao: db.syncLogDao,
      remoteDataSource: _NoopRemoteDataSource(),
      nextResult: const SyncResult(
        uploaded: 2,
        downloaded: 3,
        conflictsResolved: 1,
        success: true,
      ),
    );

    repository = SyncRepositoryImpl(
      supabaseSyncService: syncService,
      syncLogDao: syncLogDao,
      transactionsDao: transactionsDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('syncNow delegates to SupabaseSyncService', () async {
    final result = await repository.syncNow();

    expect(result.success, isTrue);
    expect(result.uploaded, 2);
    expect(result.downloaded, 3);
    expect(result.conflictsResolved, 1);
  });

  test('getLastSyncTime returns last transaction sync time', () async {
    final expectedTime = DateTime(2026, 3, 15, 12, 0);
    syncLogDao.syncLog = SyncLogModel(
      id: 1,
      tableName: SupabaseSyncService.transactionsTable,
      lastSyncedAt: expectedTime,
      status: 'success',
    );

    final result = await repository.getLastSyncTime();

    expect(result, expectedTime);
  });

  test('hasUnsyncedChanges returns false when all are synced', () async {
    final syncTime = DateTime(2026, 3, 15, 10, 0);
    transactionsDao.transactions = [
      _transaction(id: 1, syncedAt: syncTime, updatedAt: syncTime),
    ];

    final result = await repository.hasUnsyncedChanges();

    expect(result, isFalse);
  });

  test('hasUnsyncedChanges returns true when syncedAt is null', () async {
    transactionsDao.transactions = [_transaction(id: 1, syncedAt: null)];

    final result = await repository.hasUnsyncedChanges();

    expect(result, isTrue);
  });

  test('getUnsyncedChangesCount returns number of pending changes', () async {
    final syncedAt = DateTime(2026, 3, 14, 10, 0);
    transactionsDao.transactions = [
      _transaction(id: 1, syncedAt: null),
      _transaction(id: 2, syncedAt: syncedAt, updatedAt: DateTime(2026, 3, 15)),
      _transaction(id: 3, syncedAt: syncedAt, updatedAt: syncedAt),
    ];

    final count = await repository.getUnsyncedChangesCount();

    expect(count, 2);
  });

  test('hasUnsyncedChanges returns true when updatedAt > syncedAt', () async {
    final syncedAt = DateTime(2026, 3, 14, 10, 0);
    final updatedAt = DateTime(2026, 3, 15, 10, 0);
    transactionsDao.transactions = [
      _transaction(id: 1, syncedAt: syncedAt, updatedAt: updatedAt),
    ];

    final result = await repository.hasUnsyncedChanges();

    expect(result, isTrue);
  });
}
