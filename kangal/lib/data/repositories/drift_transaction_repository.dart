import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'transaction_repository.dart';

class DriftTransactionRepository implements TransactionRepository {
  final TransactionsDao _dao;

  DriftTransactionRepository(this._dao);

  @override
  Future<List<TransactionModel>> getAllTransactions(int limit, int offset) =>
      _dao.getAllTransactions(limit, offset);

  @override
  Future<TransactionModel?> getTransactionById(int id) =>
      _dao.getTransactionById(id);

  @override
  Future<TransactionModel?> getTransactionByTransactionId(String txnId) =>
      _dao.getTransactionByTransactionId(txnId);

  @override
  Future<int> insertTransaction(TransactionModel transaction) =>
      _dao.insertTransaction(transaction);

  @override
  Future<bool> updateTransaction(TransactionModel transaction) =>
      _dao.updateTransaction(transaction);

  @override
  Future<int> deleteTransaction(int id) => _dao.deleteTransaction(id);

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) => _dao.getTransactionsByDateRange(start, end);

  @override
  Future<List<TransactionModel>> getTransactionsBySource(String source) =>
      _dao.getTransactionsBySource(source);

  @override
  Future<List<TransactionModel>> searchTransactions(String query) =>
      _dao.searchTransactions(query);

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() =>
      _dao.getUnsyncedTransactions();

  @override
  Future<TransactionSummary> getSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _dao.getTransactionsByDateRange(
      startDate,
      endDate,
    );
    double totalSpent = 0;
    double totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.amount < 0) {
        totalSpent += transaction.amount.abs();
      } else {
        totalIncome += transaction.amount;
      }
    }

    return TransactionSummary(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      netBalance: totalIncome - totalSpent,
      transactionCount: transactions.length,
    );
  }

  @override
  Future<List<DailySpend>> getDailySpend(DateTime startDate, DateTime endDate) {
    return _dao.getDailySpend(startDate, endDate);
  }

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dao.getCategorySpend(startDate, endDate);
  }
}
