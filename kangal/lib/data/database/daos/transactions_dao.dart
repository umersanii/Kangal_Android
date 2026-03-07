import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../../models/transaction_model.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async {
    final rows = await (select(
      transactionsTable,
    )..limit(limit, offset: offset)).get();
    return rows.map(_toModel).toList();
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final row = await (select(
      transactionsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<TransactionModel?> getTransactionByTransactionId(String txnId) async {
    final row = await (select(
      transactionsTable,
    )..where((t) => t.transactionId.equals(txnId))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<int> insertTransaction(TransactionModel transaction) {
    return into(transactionsTable).insert(
      TransactionsTableCompanion(
        remoteId: Value(transaction.remoteId),
        date: Value(transaction.date.toIso8601String()),
        amount: Value(transaction.amount),
        source: Value(transaction.source),
        type: Value(transaction.type),
        transactionId: Value(transaction.transactionId),
        beneficiary: Value(transaction.beneficiary),
        subject: Value(transaction.subject),
        categoryId: Value(transaction.categoryId),
        note: Value(transaction.note),
        extra: Value(transaction.extra),
        syncedAt: Value(transaction.syncedAt),
        updatedAt: Value(transaction.updatedAt),
        createdAt: Value(transaction.createdAt),
      ),
    );
  }

  Future<bool> updateTransaction(TransactionModel transaction) {
    return update(transactionsTable).replace(
      TransactionsTableCompanion(
        id: Value(transaction.id),
        remoteId: Value(transaction.remoteId),
        date: Value(transaction.date.toIso8601String()),
        amount: Value(transaction.amount),
        source: Value(transaction.source),
        type: Value(transaction.type),
        transactionId: Value(transaction.transactionId),
        beneficiary: Value(transaction.beneficiary),
        subject: Value(transaction.subject),
        categoryId: Value(transaction.categoryId),
        note: Value(transaction.note),
        extra: Value(transaction.extra),
        syncedAt: Value(transaction.syncedAt),
        updatedAt: Value(transaction.updatedAt),
        createdAt: Value(transaction.createdAt),
      ),
    );
  }

  Future<int> deleteTransaction(int id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await (select(transactionsTable)..where(
              (t) => t.date.isBetweenValues(
                start.toIso8601String(),
                end.toIso8601String(),
              ),
            ))
            .get();
    return rows.map(_toModel).toList();
  }

  Future<List<TransactionModel>> getTransactionsBySource(String source) async {
    final rows = await (select(
      transactionsTable,
    )..where((t) => t.source.equals(source))).get();
    return rows.map(_toModel).toList();
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final rows = await (select(
      transactionsTable,
    )..where((t) => t.note.like('%$query%'))).get();
    return rows.map(_toModel).toList();
  }

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final rows = await (select(
      transactionsTable,
    )..where((t) => t.syncedAt.isNull())).get();
    return rows.map(_toModel).toList();
  }

  TransactionModel _toModel(TransactionsTableData row) {
    return TransactionModel(
      id: row.id,
      remoteId: row.remoteId,
      date: DateTime.parse(row.date),
      amount: row.amount,
      source: row.source,
      type: row.type,
      transactionId: row.transactionId,
      beneficiary: row.beneficiary,
      subject: row.subject,
      categoryId: row.categoryId,
      note: row.note,
      extra: row.extra,
      syncedAt: row.syncedAt,
      updatedAt: row.updatedAt,
      createdAt: row.createdAt,
    );
  }
}
