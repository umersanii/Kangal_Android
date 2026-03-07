import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(AppDatabase db) : super(db);

  Future<List<Transaction>> getAllTransactions(int limit, int offset) => (select(transactionsTable)
        ..limit(limit, offset: offset))
      .get();

  Future<Transaction?> getTransactionById(int id) => (select(transactionsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Transaction?> getTransactionByTransactionId(String txnId) => (select(transactionsTable)..where((t) => t.transactionId.equals(txnId))).getSingleOrNull();

  Future<int> insertTransaction(Insertable<Transaction> companion) => into(transactionsTable).insert(companion);

  Future<bool> updateTransaction(Insertable<Transaction> companion) => update(transactionsTable).replace(companion);

  Future<int> deleteTransaction(int id) => (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) => (select(transactionsTable)
        ..where((t) => t.date.isBetweenValues(start, end)))
      .get();

  Future<List<Transaction>> getTransactionsBySource(String source) => (select(transactionsTable)..where((t) => t.source.equals(source))).get();

  Future<List<Transaction>> searchTransactions(String query) => (select(transactionsTable)..where((t) => t.note.like('%$query%'))).get();

  Future<List<Transaction>> getUnsyncedTransactions() => (select(transactionsTable)..where((t) => t.syncedAt.isNull())).get();
}