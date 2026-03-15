import 'package:kangal/data/database/daos/categories_dao.dart';
import 'package:kangal/data/database/daos/rules_dao.dart';
import 'package:kangal/data/database/daos/sync_log_dao.dart';
import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/sync_log_model.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseSyncRemoteDataSource {
  Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  });

  Future<List<Map<String, dynamic>>> fetchUpdated(
    String table, {
    DateTime? updatedAfter,
  });

  Future<List<Map<String, dynamic>>> fetchAll(String table);
}

class SupabaseSyncRemoteDataSourceAdapter
    implements SupabaseSyncRemoteDataSource {
  final SupabaseClient _client;

  SupabaseSyncRemoteDataSourceAdapter(this._client);

  @override
  Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async {
    if (rows.isEmpty) {
      return const [];
    }

    final response = await _client
        .from(table)
        .upsert(rows, onConflict: onConflict)
        .select();
    return _asMapList(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUpdated(
    String table, {
    DateTime? updatedAfter,
  }) async {
    if (updatedAfter == null) {
      final response = await _client.from(table).select();
      return _asMapList(response);
    }

    final response = await _client
        .from(table)
        .select()
        .gt('updated_at', updatedAfter.toIso8601String());
    return _asMapList(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final response = await _client.from(table).select();
    return _asMapList(response);
  }

  List<Map<String, dynamic>> _asMapList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}

class SupabaseSyncService {
  static const String transactionsTable = 'transactions';
  static const String categoriesTable = 'categories';
  static const String rulesTable = 'rules';

  final TransactionsDao _transactionsDao;
  final CategoriesDao _categoriesDao;
  final RulesDao _rulesDao;
  final SyncLogDao _syncLogDao;
  final SupabaseAuthService _authService;
  final SupabaseSyncRemoteDataSource _remote;

  SupabaseSyncService({
    required TransactionsDao transactionsDao,
    required CategoriesDao categoriesDao,
    required RulesDao rulesDao,
    required SyncLogDao syncLogDao,
    SupabaseClient? supabaseClient,
    SupabaseAuthService? authService,
    SupabaseSyncRemoteDataSource? remoteDataSource,
  }) : _transactionsDao = transactionsDao,
       _categoriesDao = categoriesDao,
       _rulesDao = rulesDao,
       _syncLogDao = syncLogDao,
       _authService = authService ?? SupabaseAuthService(),
       _remote =
           remoteDataSource ??
           SupabaseSyncRemoteDataSourceAdapter(
             supabaseClient ?? Supabase.instance.client,
           );

  Future<SyncResult> syncAll() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return const SyncResult(
          uploaded: 0,
          downloaded: 0,
          conflictsResolved: 0,
          success: false,
          errorMessage: 'User is not authenticated',
        );
      }

      final syncTime = DateTime.now();

      var uploaded = 0;
      uploaded += await _uploadTransactions(userId, syncTime);
      uploaded += await _uploadCategories(userId);
      uploaded += await _uploadRules(userId);

      var downloaded = 0;
      var conflictsResolved = 0;

      final transactionDownload = await _downloadTransactions();
      downloaded += transactionDownload.downloaded;
      conflictsResolved += transactionDownload.conflictsResolved;

      final categoryDownload = await _downloadCategories();
      downloaded += categoryDownload;

      final ruleDownload = await _downloadRules();
      downloaded += ruleDownload;

      await _upsertSyncLog(transactionsTable, syncTime, 'success');
      await _upsertSyncLog(categoriesTable, syncTime, 'success');
      await _upsertSyncLog(rulesTable, syncTime, 'success');

      return SyncResult(
        uploaded: uploaded,
        downloaded: downloaded,
        conflictsResolved: conflictsResolved,
        success: true,
      );
    } catch (error) {
      return SyncResult(
        uploaded: 0,
        downloaded: 0,
        conflictsResolved: 0,
        success: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<int> _uploadTransactions(String userId, DateTime syncedAt) async {
    final transactions = await _transactionsDao.getAllTransactions(1000000, 0);
    final toUpload = transactions
        .where(
          (t) =>
              t.syncedAt == null ||
              (t.syncedAt != null && t.updatedAt.isAfter(t.syncedAt!)),
        )
        .toList();

    if (toUpload.isEmpty) {
      return 0;
    }

    final payload = toUpload
        .map((transaction) => _transactionToRemote(transaction, userId))
        .toList();

    await _remote.upsert(
      transactionsTable,
      payload,
      onConflict: 'transaction_id',
    );

    for (final transaction in toUpload) {
      await _transactionsDao.updateTransaction(
        transaction.copyWith(syncedAt: syncedAt),
      );
    }

    return toUpload.length;
  }

  Future<int> _uploadCategories(String userId) async {
    final categories = await _categoriesDao.getAllCategories();
    if (categories.isEmpty) {
      return 0;
    }

    final payload = categories
        .map(
          (category) => {
            'id': category.id,
            'user_id': userId,
            'name': category.name,
            'emoji': category.emoji,
            'color': category.color,
            'is_default': category.isDefault,
          },
        )
        .toList();

    await _remote.upsert(categoriesTable, payload, onConflict: 'id');
    return categories.length;
  }

  Future<int> _uploadRules(String userId) async {
    final rules = await _rulesDao.getAllRules();
    if (rules.isEmpty) {
      return 0;
    }

    final payload = rules
        .map(
          (rule) => {
            'id': rule.id,
            'user_id': userId,
            'keyword': rule.keyword,
            'category_id': rule.categoryId,
          },
        )
        .toList();

    await _remote.upsert(rulesTable, payload, onConflict: 'id');
    return rules.length;
  }

  Future<({int downloaded, int conflictsResolved})>
  _downloadTransactions() async {
    final lastSync = await _syncLogDao.getLastSync(transactionsTable);
    final remoteRows = await _remote.fetchUpdated(
      transactionsTable,
      updatedAfter: lastSync?.lastSyncedAt,
    );

    if (remoteRows.isEmpty) {
      return (downloaded: 0, conflictsResolved: 0);
    }

    final localTransactions = await _transactionsDao.getAllTransactions(
      1000000,
      0,
    );
    final byRemoteId = <String, TransactionModel>{
      for (final tx in localTransactions)
        if (tx.remoteId != null && tx.remoteId!.isNotEmpty) tx.remoteId!: tx,
    };
    final byTransactionId = <String, TransactionModel>{
      for (final tx in localTransactions)
        if (tx.transactionId != null && tx.transactionId!.isNotEmpty)
          tx.transactionId!: tx,
    };

    var downloaded = 0;
    var conflictsResolved = 0;

    for (final row in remoteRows) {
      final remoteModel = _remoteRowToTransaction(row);
      final remoteId = remoteModel.remoteId;
      final transactionId = remoteModel.transactionId;

      TransactionModel? existing;
      if (remoteId != null && remoteId.isNotEmpty) {
        existing = byRemoteId[remoteId];
      }
      existing ??= (transactionId != null && transactionId.isNotEmpty)
          ? byTransactionId[transactionId]
          : null;

      if (existing == null) {
        await _transactionsDao.insertTransaction(remoteModel);
        downloaded++;
        continue;
      }

      if (remoteModel.updatedAt.isAfter(existing.updatedAt)) {
        final merged = remoteModel.copyWith(id: existing.id);
        await _transactionsDao.updateTransaction(merged);
        downloaded++;
        conflictsResolved++;
      }
    }

    return (downloaded: downloaded, conflictsResolved: conflictsResolved);
  }

  Future<int> _downloadCategories() async {
    final remoteRows = await _remote.fetchAll(categoriesTable);
    if (remoteRows.isEmpty) {
      return 0;
    }

    var downloaded = 0;
    for (final row in remoteRows) {
      final id = (row['id'] as num?)?.toInt();
      if (id == null) {
        continue;
      }

      final model = CategoryModel(
        id: id,
        name: (row['name'] ?? '').toString(),
        emoji: (row['emoji'] ?? '').toString(),
        color: (row['color'] ?? '').toString(),
        isDefault: (row['is_default'] as bool?) ?? false,
      );

      final existing = await _categoriesDao.getCategoryById(id);
      if (existing == null) {
        await _categoriesDao.insertCategory(model);
      } else {
        await _categoriesDao.updateCategory(model);
      }
      downloaded++;
    }

    return downloaded;
  }

  Future<int> _downloadRules() async {
    final remoteRows = await _remote.fetchAll(rulesTable);
    if (remoteRows.isEmpty) {
      return 0;
    }

    final existingRules = await _rulesDao.getAllRules();
    final byId = {for (final rule in existingRules) rule.id: rule};

    var downloaded = 0;
    for (final row in remoteRows) {
      final id = (row['id'] as num?)?.toInt();
      final keyword = row['keyword']?.toString();
      final categoryId = (row['category_id'] as num?)?.toInt();
      if (id == null || keyword == null || categoryId == null) {
        continue;
      }

      final model = RuleModel(id: id, keyword: keyword, categoryId: categoryId);
      if (byId.containsKey(id)) {
        await _rulesDao.updateRule(model);
      } else {
        await _rulesDao.insertRule(model);
      }
      downloaded++;
    }

    return downloaded;
  }

  Future<void> _upsertSyncLog(
    String tableName,
    DateTime syncTime,
    String status,
  ) async {
    final existing = await _syncLogDao.getLastSync(tableName);
    await _syncLogDao.upsertSyncLog(
      SyncLogModel(
        id: existing?.id ?? _defaultSyncLogIdForTable(tableName),
        tableName: tableName,
        lastSyncedAt: syncTime,
        status: status,
      ),
    );
  }

  int _defaultSyncLogIdForTable(String tableName) {
    switch (tableName) {
      case transactionsTable:
        return 1;
      case categoriesTable:
        return 2;
      case rulesTable:
        return 3;
      default:
        return 999;
    }
  }

  Map<String, dynamic> _transactionToRemote(
    TransactionModel transaction,
    String userId,
  ) {
    return {
      'user_id': userId,
      'remote_id': transaction.remoteId,
      'date': transaction.date.toIso8601String(),
      'amount': transaction.amount,
      'source': transaction.source,
      'type': transaction.type,
      'transaction_id': transaction.transactionId,
      'beneficiary': transaction.beneficiary,
      'subject': transaction.subject,
      'category_id': transaction.categoryId,
      'note': transaction.note,
      'extra': transaction.extra,
      'synced_at': transaction.syncedAt?.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
      'created_at': transaction.createdAt.toIso8601String(),
    };
  }

  TransactionModel _remoteRowToTransaction(Map<String, dynamic> row) {
    return TransactionModel(
      id: 0,
      remoteId: row['id']?.toString(),
      date: _parseDateTime(row['date']) ?? DateTime.now(),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      source: (row['source'] ?? '').toString(),
      type: row['type']?.toString(),
      transactionId: row['transaction_id']?.toString(),
      beneficiary: row['beneficiary']?.toString(),
      subject: row['subject']?.toString(),
      categoryId: (row['category_id'] as num?)?.toInt(),
      note: row['note']?.toString(),
      extra: row['extra']?.toString(),
      syncedAt: _parseDateTime(row['synced_at']),
      updatedAt: _parseDateTime(row['updated_at']) ?? DateTime.now(),
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
