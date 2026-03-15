import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../../models/transaction_model.dart';
import '../../models/daily_spend.dart';
import '../../models/category_spend.dart';

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
    )
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
      ..limit(limit, offset: offset)).get();
    return rows.map(_toModel).toList();
  }

  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = select(transactionsTable);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((t) => t.beneficiary.like('%$searchQuery%') | t.note.like('%$searchQuery%') | t.subject.like('%$searchQuery%'));
    }
    if (sourceFilter != null && sourceFilter.isNotEmpty && sourceFilter != 'All') {
      query.where((t) => t.source.equals(sourceFilter));
    }
    if (categoryFilter != null) {
      query.where((t) => t.categoryId.equals(categoryFilter));
    }
    if (startDate != null && endDate != null) {
      query.where((t) => t.date.isBetweenValues(startDate.toIso8601String(), endDate.toIso8601String()));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    query.limit(limit, offset: offset);
    final rows = await query.get();
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

  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async {
    return (update(transactionsTable)
          ..where((t) => t.categoryId.equals(oldCategoryId)))
        .write(TransactionsTableCompanion(categoryId: Value(newCategoryId)));
  }

  Future<List<DailySpend>> getDailySpend(DateTime start, DateTime end) async {
    final rows = await getTransactionsByDateRange(start, end);
    final map = <DateTime, double>{};
    for (final row in rows) {
      if (row.amount < 0) {
        final d = DateTime(row.date.year, row.date.month, row.date.day);
        map[d] = (map[d] ?? 0) + row.amount.abs();
      }
    }
    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys
        .map((k) => DailySpend(date: k, totalSpent: map[k]!))
        .toList();
  }

  Future<List<CategorySpend>> getCategorySpend(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await getTransactionsByDateRange(start, end);
    final map = <int?, double>{};
    for (final row in rows) {
      if (row.amount < 0) {
        map[row.categoryId] = (map[row.categoryId] ?? 0) + row.amount.abs();
      }
    }

    final result = <CategorySpend>[];
    for (final entry in map.entries) {
      final categoryId = entry.key;
      String? categoryName;
      String? emoji;
      String? color;

      if (categoryId != null) {
        final catRow = await (select(
          categoriesTable,
        )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
        if (catRow != null) {
          categoryName = catRow.name;
          emoji = catRow.emoji;
          color = catRow.color;
        }
      }

      result.add(
        CategorySpend(
          categoryId: categoryId,
          categoryName: categoryName,
          emoji: emoji,
          color: color,
          totalSpent: entry.value,
        ),
      );
    }
    result.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return result;
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
