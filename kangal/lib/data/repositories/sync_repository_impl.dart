import 'package:kangal/data/database/daos/sync_log_dao.dart';
import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/repositories/sync_repository.dart';
import 'package:kangal/data/services/supabase_sync_service.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SupabaseSyncService _supabaseSyncService;
  final SyncLogDao _syncLogDao;
  final TransactionsDao _transactionsDao;

  SyncRepositoryImpl({
    required SupabaseSyncService supabaseSyncService,
    required SyncLogDao syncLogDao,
    required TransactionsDao transactionsDao,
  }) : _supabaseSyncService = supabaseSyncService,
       _syncLogDao = syncLogDao,
       _transactionsDao = transactionsDao;

  @override
  Future<SyncResult> syncNow() {
    return _supabaseSyncService.syncAll();
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final log = await _syncLogDao.getLastSync(
      SupabaseSyncService.transactionsTable,
    );
    return log?.lastSyncedAt;
  }

  @override
  Future<bool> hasUnsyncedChanges() async {
    final transactions = await _transactionsDao.getAllTransactions(1000000, 0);
    return transactions.any(
      (transaction) =>
          transaction.syncedAt == null ||
          (transaction.syncedAt != null &&
              transaction.updatedAt.isAfter(transaction.syncedAt!)),
    );
  }
}
