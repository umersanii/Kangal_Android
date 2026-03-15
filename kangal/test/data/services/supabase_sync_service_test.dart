import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:kangal/data/services/supabase_sync_service.dart';

class _FakeAuthService extends SupabaseAuthService {
  final String? userId;

  _FakeAuthService(this.userId);

  @override
  String? getCurrentUserId() => userId;
}

class _FakeRemoteDataSource implements SupabaseSyncRemoteDataSource {
  final Map<String, List<Map<String, dynamic>>> upsertedRows = {};
  final Map<String, List<Map<String, dynamic>>> updatedRowsByTable = {};
  final Map<String, List<Map<String, dynamic>>> allRowsByTable = {};

  @override
  Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async {
    upsertedRows
        .putIfAbsent(table, () => <Map<String, dynamic>>[])
        .addAll(rows);
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUpdated(
    String table, {
    DateTime? updatedAfter,
  }) async {
    return updatedRowsByTable[table] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    return allRowsByTable[table] ?? const [];
  }
}

TransactionModel _transaction({
  required int id,
  String? remoteId,
  required String transactionId,
  required double amount,
  DateTime? syncedAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 3, 15, 10, 0, 0);
  return TransactionModel(
    id: id,
    remoteId: remoteId,
    date: now,
    amount: amount,
    source: 'NayaPay',
    type: 'card_purchase',
    transactionId: transactionId,
    beneficiary: 'Merchant',
    subject: 'Subject',
    categoryId: null,
    note: null,
    extra: null,
    syncedAt: syncedAt,
    updatedAt: updatedAt ?? now,
    createdAt: now,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(e: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'syncAll uploads unsynced local transactions and marks syncedAt',
    () async {
      await db.transactionsDao.insertTransaction(
        _transaction(
          id: 0,
          transactionId: 'txn-upload-1',
          amount: -500,
          syncedAt: null,
        ),
      );

      final remote = _FakeRemoteDataSource();
      final service = SupabaseSyncService(
        transactionsDao: db.transactionsDao,
        categoriesDao: db.categoriesDao,
        rulesDao: db.rulesDao,
        syncLogDao: db.syncLogDao,
        authService: _FakeAuthService('user-1'),
        remoteDataSource: remote,
      );

      final result = await service.syncAll();

      expect(result.success, isTrue);
      expect(result.uploaded, greaterThanOrEqualTo(1));
      expect(
        remote.upsertedRows[SupabaseSyncService.transactionsTable],
        isNotEmpty,
      );

      final transactions = await db.transactionsDao.getAllTransactions(10, 0);
      expect(transactions.single.syncedAt, isNotNull);
    },
  );

  test(
    'syncAll downloads updated remote transaction and resolves conflict',
    () async {
      final local = _transaction(
        id: 0,
        remoteId: '10',
        transactionId: 'txn-remote-10',
        amount: -100,
        syncedAt: DateTime(2026, 3, 10),
        updatedAt: DateTime(2026, 3, 10),
      );
      await db.transactionsDao.insertTransaction(local);

      final remote = _FakeRemoteDataSource();
      remote.updatedRowsByTable[SupabaseSyncService.transactionsTable] = [
        {
          'id': 10,
          'date': DateTime(2026, 3, 15, 12, 0, 0).toIso8601String(),
          'amount': -750.0,
          'source': 'NayaPay',
          'type': 'card_purchase',
          'transaction_id': 'txn-remote-10',
          'beneficiary': 'Updated Merchant',
          'subject': 'Updated subject',
          'category_id': null,
          'note': null,
          'extra': null,
          'synced_at': DateTime(2026, 3, 15, 12, 0, 0).toIso8601String(),
          'updated_at': DateTime(2026, 3, 15, 12, 0, 0).toIso8601String(),
          'created_at': DateTime(2026, 3, 15, 12, 0, 0).toIso8601String(),
        },
      ];

      final service = SupabaseSyncService(
        transactionsDao: db.transactionsDao,
        categoriesDao: db.categoriesDao,
        rulesDao: db.rulesDao,
        syncLogDao: db.syncLogDao,
        authService: _FakeAuthService('user-1'),
        remoteDataSource: remote,
      );

      final result = await service.syncAll();

      expect(result.success, isTrue);
      expect(result.downloaded, greaterThanOrEqualTo(1));
      expect(result.conflictsResolved, greaterThanOrEqualTo(1));

      final transactions = await db.transactionsDao.getAllTransactions(10, 0);
      expect(transactions.single.amount, -750.0);
      expect(transactions.single.beneficiary, 'Updated Merchant');
    },
  );

  test('syncAll returns failure when user is not authenticated', () async {
    final remote = _FakeRemoteDataSource();
    final service = SupabaseSyncService(
      transactionsDao: db.transactionsDao,
      categoriesDao: db.categoriesDao,
      rulesDao: db.rulesDao,
      syncLogDao: db.syncLogDao,
      authService: _FakeAuthService(null),
      remoteDataSource: remote,
    );

    final result = await service.syncAll();

    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
    expect(result.uploaded, 0);
    expect(result.downloaded, 0);
  });
}
