import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/settings/categories/categories_view_model.dart';

class MockCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = [];
  bool throwError = false;
  int deleteCalledWithId = -1;
  int insertCalledCount = 0;
  int updateCalledCount = 0;

  @override
  Future<int> deleteCategory(int id) async {
    if (throwError) throw Exception('Mock error');
    deleteCalledWithId = id;
    categories.removeWhere((c) => c.id == id);
    return 1;
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    if (throwError) throw Exception('Mock error');
    return categories;
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    if (throwError) throw Exception('Mock error');
    return categories.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<CategoryModel>> getDefaultCategories() async {
    if (throwError) throw Exception('Mock error');
    return categories.where((c) => c.isDefault).toList();
  }

  @override
  Future<int> insertCategory(CategoryModel category) async {
    if (throwError) throw Exception('Mock error');
    insertCalledCount++;
    categories.add(category.copyWith(id: categories.length + 1));
    return 1;
  }

  @override
  Future<bool> updateCategory(CategoryModel category) async {
    if (throwError) throw Exception('Mock error');
    updateCalledCount++;
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      return true;
    }
    return false;
  }
}

class MockTransactionRepository implements TransactionRepository {
  int reassignOldId = -1;
  int reassignNewId = -1;

  @override
  Future<int> deleteTransaction(int id) async => 1;

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
  Future<TransactionModel?> getTransactionById(int id) async => null;

  @override
  Future<TransactionModel?> getTransactionByTransactionId(
    String transactionId,
  ) async => null;

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

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime start,
    DateTime end,
  ) async => [];

  @override
  Future<List<DailySpend>> getDailySpend(DateTime start, DateTime end) async =>
      [];

  @override
  Future<TransactionSummary> getSummary(DateTime start, DateTime end) async {
    return TransactionSummary(
      totalSpent: 0,
      totalIncome: 0,
      netBalance: 0,
      transactionCount: 0,
    );
  }

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async {
    reassignOldId = oldCategoryId;
    reassignNewId = newCategoryId;
    return 1;
  }
}

void main() {
  late CategoriesViewModel viewModel;
  late MockCategoryRepository mockCategoryRepository;
  late MockTransactionRepository mockTransactionRepository;

  final customCategory = const CategoryModel(
    id: 1,
    name: 'Custom',
    emoji: '🌟',
    color: '#111111',
    isDefault: false,
  );
  final defaultCategoryOther = const CategoryModel(
    id: 2,
    name: 'Other',
    emoji: '📦',
    color: '#95A5A6',
    isDefault: true,
  );
  final defaultCategoryFood = const CategoryModel(
    id: 3,
    name: 'Food',
    emoji: '🍕',
    color: '#FF5733',
    isDefault: true,
  );

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockTransactionRepository = MockTransactionRepository();
    viewModel = CategoriesViewModel(
      categoryRepository: mockCategoryRepository,
      transactionRepository: mockTransactionRepository,
    );
  });

  group('CategoriesViewModel', () {
    test('loadCategories populates categories list', () async {
      mockCategoryRepository.categories = [
        customCategory,
        defaultCategoryOther,
      ];

      await viewModel.loadCategories();

      expect(viewModel.categories.length, 2);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('addCategory calls repository and reloads', () async {
      await viewModel.addCategory('NewCat', '😺', '#000000');

      expect(mockCategoryRepository.insertCalledCount, 1);
      expect(viewModel.categories.length, 1);
      expect(viewModel.categories.first.name, 'NewCat');
    });

    test('updateCategory calls repository and reloads', () async {
      mockCategoryRepository.categories = [customCategory];
      await viewModel.loadCategories();

      await viewModel.updateCategory(1, 'Updated', '🌟', '#111111');

      expect(mockCategoryRepository.updateCalledCount, 1);
      expect(viewModel.categories.first.name, 'Updated');
    });

    test('deleteCategory prevents deletion of default category', () async {
      mockCategoryRepository.categories = [defaultCategoryFood];
      await viewModel.loadCategories();

      final result = await viewModel.deleteCategory(3);

      expect(result, false);
      expect(
        viewModel.errorMessage,
        contains('Cannot delete a default category'),
      );
      expect(mockCategoryRepository.deleteCalledWithId, -1); // not called
    });

    test(
      'deleteCategory reassigns to Other and deletes custom category',
      () async {
        mockCategoryRepository.categories = [
          customCategory,
          defaultCategoryOther,
        ];
        await viewModel.loadCategories();

        final result = await viewModel.deleteCategory(1);

        expect(result, true);
        expect(mockTransactionRepository.reassignOldId, 1);
        expect(
          mockTransactionRepository.reassignNewId,
          2,
        ); // 'Other' category ID
        expect(mockCategoryRepository.deleteCalledWithId, 1);
        expect(viewModel.categories.length, 1); // Only 'Other' remains
      },
    );

    test('deleteCategory fails if Other category is not found', () async {
      mockCategoryRepository.categories = [
        customCategory,
      ]; // Note: missing 'Other'
      await viewModel.loadCategories();

      final result = await viewModel.deleteCategory(1);

      expect(result, false);
      expect(viewModel.errorMessage, contains('Other'));
      expect(mockCategoryRepository.deleteCalledWithId, -1);
    });
  });
}
