import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions(int limit, int offset);
  Future<Transaction?> getTransactionById(int id);
  Future<Transaction?> getTransactionByTransactionId(String txnId);
  Future<int> insertTransaction(Transaction transaction);
  Future<bool> updateTransaction(Transaction transaction);
  Future<int> deleteTransaction(int id);
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<List<Transaction>> getTransactionsBySource(String source);
  Future<List<Transaction>> searchTransactions(String query);
  Future<List<Transaction>> getUnsyncedTransactions();
  Future<TransactionSummary> getSummary(DateTime startDate, DateTime endDate);
}

class TransactionSummary {
  final double totalSpent;
  final double totalIncome;
  final double netBalance;
  final int transactionCount;

  TransactionSummary({
    required this.totalSpent,
    required this.totalIncome,
    required this.netBalance,
    required this.transactionCount,
  });
}
