import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'transaction_repository.dart';

class DriftTransactionRepository implements TransactionRepository {
  final TransactionsDao _dao;

  DriftTransactionRepository(this._dao);

  @override
  Future<List<Transaction>> getAllTransactions(int limit, int offset) =>
      _dao.getAllTransactions(limit, offset);

  @override
  Future<Transaction?> getTransactionById(int id) =>
      _dao.getTransactionById(id);

  @override
  Future<Transaction?> getTransactionByTransactionId(String txnId) =>
      _dao.getTransactionByTransactionId(txnId);

  @override
  Future<int> insertTransaction(Transaction transaction) =>
      _dao.insertTransaction(transaction);

  @override
  Future<bool> updateTransaction(Transaction transaction) =>
      _dao.updateTransaction(transaction);

  @override
  Future<int> deleteTransaction(int id) => _dao.deleteTransaction(id);

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) => _dao.getTransactionsByDateRange(start, end);

  @override
  Future<List<Transaction>> getTransactionsBySource(String source) =>
      _dao.getTransactionsBySource(source);

  @override
  Future<List<Transaction>> searchTransactions(String query) =>
      _dao.searchTransactions(query);

  @override
  Future<List<Transaction>> getUnsyncedTransactions() =>
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
}
