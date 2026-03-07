import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kangal/data/repositories/drift_transaction_repository.dart';
import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/transaction_model.dart';

class MockTransactionsDao extends Mock implements TransactionsDao {}

void main() {
  late MockTransactionsDao mockDao;
  late DriftTransactionRepository repository;

  setUp(() {
    mockDao = MockTransactionsDao();
    repository = DriftTransactionRepository(mockDao);
  });

  test('getAllTransactions calls DAO method', () async {
    when(mockDao.getAllTransactions(10, 0)).thenAnswer((_) async => []);

    final result = await repository.getAllTransactions(10, 0);

    verify(mockDao.getAllTransactions(10, 0)).called(1);
    expect(result, isEmpty);
  });

  test('getSummary calculates correct totals', () async {
    final startDate = DateTime(2026, 1, 1);
    final endDate = DateTime(2026, 1, 31);

    final transactions = [
      TransactionModel(
        id: 1,
        amount: -100.0,
        date: DateTime.now(),
        source: 'test',
        type: 'expense',
        transactionId: 'txn1',
        beneficiary: 'test',
        subject: 'test',
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      TransactionModel(
        id: 2,
        amount: 200.0,
        date: DateTime.now(),
        source: 'test',
        type: 'income',
        transactionId: 'txn2',
        beneficiary: 'test',
        subject: 'test',
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];

    when(
      mockDao.getTransactionsByDateRange(startDate, endDate),
    ).thenAnswer((_) async => transactions);

    final summary = await repository.getSummary(startDate, endDate);

    expect(summary.totalSpent, 100.0);
    expect(summary.totalIncome, 200.0);
    expect(summary.netBalance, 100.0);
    expect(summary.transactionCount, 2);
  });
}
