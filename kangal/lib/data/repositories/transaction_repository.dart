import 'package:kangal/data/models/transaction_model.dart';

import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/category_spend.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getAllTransactions(int limit, int offset);
  Future<TransactionModel?> getTransactionById(int id);
  Future<TransactionModel?> getTransactionByTransactionId(String txnId);
  Future<int> insertTransaction(TransactionModel transaction);
  Future<bool> updateTransaction(TransactionModel transaction);
  Future<int> deleteTransaction(int id);
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<List<TransactionModel>> getTransactionsBySource(String source);
  Future<List<TransactionModel>> searchTransactions(String query);
  Future<List<TransactionModel>> getUnsyncedTransactions();
  Future<TransactionSummary> getSummary(DateTime startDate, DateTime endDate);
  Future<List<DailySpend>> getDailySpend(DateTime startDate, DateTime endDate);
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  );
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId);
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
