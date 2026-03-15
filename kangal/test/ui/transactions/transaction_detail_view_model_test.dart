import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/transactions/transaction_detail_view_model.dart';

class FakeTransactionRepository implements TransactionRepository {
  TransactionModel? transaction;
  TransactionModel? updatedTransaction;
  int deleteResult = 1;

  @override
  Future<TransactionModel?> getTransactionById(int id) async => transaction;

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    updatedTransaction = transaction;
    this.transaction = transaction;
    return true;
  }

  @override
  Future<int> deleteTransaction(int id) async => deleteResult;

  @override
  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async => [];

  @override
  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<TransactionModel?> getTransactionByTransactionId(String txnId) async =>
      null;

  @override
  Future<int> insertTransaction(TransactionModel transaction) async => 1;

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async => [];

  @override
  Future<List<TransactionModel>> getTransactionsBySource(String source) async =>
      [];

  @override
  Future<List<TransactionModel>> searchTransactions(String query) async => [];

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async => [];

  @override
  Future<TransactionSummary> getSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return TransactionSummary(
      totalSpent: 0,
      totalIncome: 0,
      netBalance: 0,
      transactionCount: 0,
    );
  }

  @override
  Future<List<DailySpend>> getDailySpend(
    DateTime startDate,
    DateTime endDate,
  ) async => [];

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  ) async => [];

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async => 0;
}

class FakeCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = [];

  @override
  Future<List<CategoryModel>> getAllCategories() async => categories;

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    return categories.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<int> insertCategory(CategoryModel category) async => 1;

  @override
  Future<bool> updateCategory(CategoryModel category) async => true;

  @override
  Future<int> deleteCategory(int id) async => 1;

  @override
  Future<List<CategoryModel>> getDefaultCategories() async =>
      categories.where((c) => c.isDefault).toList();
}

void main() {
  late FakeTransactionRepository transactionRepository;
  late FakeCategoryRepository categoryRepository;
  late TransactionDetailViewModel viewModel;

  final transaction = TransactionModel(
    id: 11,
    date: DateTime(2026, 3, 15, 10, 30),
    amount: -500,
    source: 'Cash',
    categoryId: 2,
    note: 'Old note',
    updatedAt: DateTime(2026, 3, 15),
    createdAt: DateTime(2026, 3, 15),
  );

  final categories = const [
    CategoryModel(
      id: 1,
      name: 'Food',
      emoji: '🍔',
      color: '#FF5733',
      isDefault: true,
    ),
    CategoryModel(
      id: 2,
      name: 'Other',
      emoji: '📦',
      color: '#95A5A6',
      isDefault: true,
    ),
  ];

  setUp(() {
    transactionRepository = FakeTransactionRepository();
    categoryRepository = FakeCategoryRepository();

    viewModel = TransactionDetailViewModel(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
    );
  });

  test('loadTransaction loads transaction and categories', () async {
    transactionRepository.transaction = transaction;
    categoryRepository.categories = categories;

    await viewModel.loadTransaction(11);

    expect(viewModel.isLoading, false);
    expect(viewModel.transaction?.id, 11);
    expect(viewModel.categories.length, 2);
  });

  test('updateCategory updates repository and local state', () async {
    viewModel.transaction = transaction;

    final success = await viewModel.updateCategory(1);

    expect(success, true);
    expect(viewModel.transaction?.categoryId, 1);
    expect(transactionRepository.updatedTransaction?.categoryId, 1);
  });

  test('updateNote updates repository and local state', () async {
    viewModel.transaction = transaction;

    final success = await viewModel.updateNote('Updated note');

    expect(success, true);
    expect(viewModel.transaction?.note, 'Updated note');
    expect(transactionRepository.updatedTransaction?.note, 'Updated note');
  });

  test('deleteTransaction removes transaction on success', () async {
    viewModel.transaction = transaction;
    transactionRepository.deleteResult = 1;

    final success = await viewModel.deleteTransaction();

    expect(success, true);
    expect(viewModel.isDeleting, false);
    expect(viewModel.transaction, isNull);
  });

  test('deleteTransaction returns false when nothing deleted', () async {
    viewModel.transaction = transaction;
    transactionRepository.deleteResult = 0;

    final success = await viewModel.deleteTransaction();

    expect(success, false);
    expect(viewModel.isDeleting, false);
    expect(viewModel.transaction, isNotNull);
  });
}
