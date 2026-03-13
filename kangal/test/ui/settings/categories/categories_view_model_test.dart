import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/settings/categories/categories_view_model.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> _categories = [];
  int _nextId = 1;
  bool shouldThrow = false;

  void seed(List<CategoryModel> initial) {
    _categories.clear();
    _categories.addAll(initial);
    if (initial.isNotEmpty) {
      _nextId = initial.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    if (shouldThrow) throw Exception('Load error');
    return List.from(_categories);
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    if (shouldThrow) throw Exception('Get error');
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CategoryModel>> getDefaultCategories() async {
    return _categories.where((c) => c.isDefault).toList();
  }

  @override
  Future<int> insertCategory(CategoryModel category) async {
    if (shouldThrow) throw Exception('Insert error');
    final newCat = category.copyWith(id: _nextId++);
    _categories.add(newCat);
    return newCat.id;
  }

  @override
  Future<bool> updateCategory(CategoryModel category) async {
    if (shouldThrow) throw Exception('Update error');
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
      return true;
    }
    return false;
  }

  @override
  Future<int> deleteCategory(int id) async {
    if (shouldThrow) throw Exception('Delete error');
    final count = _categories.where((c) => c.id == id).length;
    _categories.removeWhere((c) => c.id == id);
    return count;
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  int reassignedCount = 0;
  int lastOldCategoryId = -1;
  int lastNewCategoryId = -1;
  bool shouldThrow = false;

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async {
    if (shouldThrow) throw Exception('Reassign error');
    lastOldCategoryId = oldCategoryId;
    lastNewCategoryId = newCategoryId;
    reassignedCount++;
    return 1;
  }

  @override
  Future<int> deleteTransaction(int id) async => 0;
  @override
  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async => [];
  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  ) async => [];
  @override
  Future<List<DailySpend>> getDailySpend(
    DateTime startDate,
    DateTime endDate,
  ) async => [];
  @override
  Future<TransactionSummary> getSummary(
    DateTime startDate,
    DateTime endDate,
  ) async => TransactionSummary(
    totalSpent: 0,
    totalIncome: 0,
    netBalance: 0,
    transactionCount: 0,
  );
  @override
  Future<TransactionModel?> getTransactionById(int id) async => null;
  @override
  Future<TransactionModel?> getTransactionByTransactionId(String txnId) async =>
      null;
  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async => [];
  @override
  Future<List<TransactionModel>> getTransactionsBySource(String source) async =>
      [];
  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async => [];
  @override
  Future<int> insertTransaction(TransactionModel transaction) async => 1;
  @override
  Future<List<TransactionModel>> searchTransactions(String query) async => [];
  @override
  Future<bool> updateTransaction(TransactionModel transaction) async => true;
}

void main() {
  late CategoriesViewModel viewModel;
  late _FakeCategoryRepository categoryRepo;
  late _FakeTransactionRepository transactionRepo;

  setUp(() {
    categoryRepo = _FakeCategoryRepository();
    transactionRepo = _FakeTransactionRepository();
    viewModel = CategoriesViewModel(
      categoryRepository: categoryRepo,
      transactionRepository: transactionRepo,
    );

    categoryRepo.seed([
      const CategoryModel(
        id: 10,
        name: 'Other',
        emoji: '📦',
        color: '#95A5A6',
        isDefault: true,
      ),
      const CategoryModel(
        id: 1,
        name: 'Food',
        emoji: '🍔',
        color: '#FF0000',
        isDefault: true,
      ),
      const CategoryModel(
        id: 2,
        name: 'Custom1',
        emoji: '🚗',
        color: '#00FF00',
        isDefault: false,
      ),
    ]);
  });

  test('loadCategories populates the state', () async {
    await viewModel.loadCategories();
    expect(viewModel.categories.length, 3);
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, isNull);
  });

  test('loadCategories handles errors nicely', () async {
    categoryRepo.shouldThrow = true;
    await viewModel.loadCategories();
    expect(viewModel.categories.length, 0);
    expect(viewModel.errorMessage, contains('Load error'));
  });

  test('addCategory creates new custom category', () async {
    await viewModel.loadCategories();
    final result = await viewModel.addCategory('Custom2', '🎮', '#0000FF');

    expect(result, true);
    expect(viewModel.categories.length, 4);
    final last = viewModel.categories.last;
    expect(last.name, 'Custom2');
    expect(last.emoji, '🎮');
    expect(last.color, '#0000FF');
    expect(last.isDefault, false);
  });

  test('updateCategory updates existing category', () async {
    await viewModel.loadCategories();
    final result = await viewModel.updateCategory(
      2,
      'Updated',
      '🚀',
      '#FFFFFF',
    );

    expect(result, true);
    final c = viewModel.categories.firstWhere((c) => c.id == 2);
    expect(c.name, 'Updated');
    expect(c.emoji, '🚀');
    expect(c.color, '#FFFFFF');
  });

  test('deleteCategory refuses to delete default category', () async {
    await viewModel.loadCategories();
    final result = await viewModel.deleteCategory(1); // Food is default

    expect(result, false);
    expect(
      viewModel.errorMessage,
      contains('Cannot delete a default category'),
    );
    expect(viewModel.categories.length, 3);
  });

  test('deleteCategory reassigns and deletes custom category', () async {
    await viewModel.loadCategories();
    final result = await viewModel.deleteCategory(2);

    expect(result, true);
    expect(viewModel.categories.length, 2);
    // Custom category 2 shouldn't exist anymore
    expect(viewModel.categories.indexWhere((c) => c.id == 2), -1);

    // Verify reassignment to Other (id: 10)
    expect(transactionRepo.reassignedCount, 1);
    expect(transactionRepo.lastOldCategoryId, 2);
    expect(transactionRepo.lastNewCategoryId, 10);
  });
}
