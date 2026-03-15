import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/settings/rules/rules_view_model.dart';

class MockRuleRepository implements RuleRepository {
  List<RuleModel> rules = [];
  bool throwError = false;
  int deleteCalledWithId = -1;
  int insertCalledCount = 0;
  int updateCalledCount = 0;

  @override
  Future<int> deleteRule(int id) async {
    if (throwError) throw Exception('Mock error');
    deleteCalledWithId = id;
    rules.removeWhere((r) => r.id == id);
    return 1;
  }

  @override
  Future<List<RuleModel>> getAllRules() async {
    if (throwError) throw Exception('Mock error');
    return rules;
  }

  @override
  Future<RuleModel?> getRuleById(int id) async {
    if (throwError) throw Exception('Mock error');
    return rules.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<int> insertRule(RuleModel rule) async {
    if (throwError) throw Exception('Mock error');
    insertCalledCount++;
    rules.add(rule.copyWith(id: rules.length + 1));
    return 1;
  }

  @override
  Future<bool> updateRule(RuleModel rule) async {
    if (throwError) throw Exception('Mock error');
    updateCalledCount++;
    final index = rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      rules[index] = rule;
      return true;
    }
    return false;
  }
}

class MockCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = [];

  @override
  Future<int> deleteCategory(int id) async => 1;
  @override
  Future<List<CategoryModel>> getAllCategories() async => categories;
  @override
  Future<CategoryModel?> getCategoryById(int id) async => null;
  @override
  Future<List<CategoryModel>> getDefaultCategories() async => [];
  @override
  Future<int> insertCategory(CategoryModel category) async => 1;
  @override
  Future<bool> updateCategory(CategoryModel category) async => true;
}

class MockTransactionRepository implements TransactionRepository {
  List<TransactionModel> transactions = [];
  int updateCalledCount = 0;

  @override
  Future<int> deleteTransaction(int id) async => 1;

  @override
  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async => transactions;

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
  Future<bool> updateTransaction(TransactionModel transaction) async {
    updateCalledCount++;
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) transactions[index] = transaction;
    return true;
  }

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
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async => 1;
}

void main() {
  late RulesViewModel viewModel;
  late MockRuleRepository mockRuleRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockTransactionRepository mockTransactionRepository;

  setUp(() {
    mockRuleRepository = MockRuleRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockTransactionRepository = MockTransactionRepository();

    viewModel = RulesViewModel(
      ruleRepository: mockRuleRepository,
      categoryRepository: mockCategoryRepository,
      transactionRepository: mockTransactionRepository,
    );
  });

  group('RulesViewModel', () {
    test('loadRules populates rules and categories', () async {
      mockRuleRepository.rules = [
        const RuleModel(id: 1, keyword: 'netflix', categoryId: 2),
      ];
      mockCategoryRepository.categories = [
        const CategoryModel(
          id: 2,
          name: 'Entertainment',
          emoji: '🎥',
          color: '#111111',
          isDefault: true,
        ),
      ];

      await viewModel.loadRules();

      expect(viewModel.rules.length, 1);
      expect(viewModel.categories.length, 1);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('addRule calls repository and reloads', () async {
      await viewModel.addRule('spotify', 2);

      expect(mockRuleRepository.insertCalledCount, 1);
      expect(viewModel.rules.length, 1);
      expect(viewModel.rules.first.keyword, 'spotify');
    });

    test('updateRule calls repository and reloads', () async {
      mockRuleRepository.rules = [
        const RuleModel(id: 1, keyword: 'netflix', categoryId: 2),
      ];
      await viewModel.loadRules();

      await viewModel.updateRule(1, 'netflix inc', 3);

      expect(mockRuleRepository.updateCalledCount, 1);
      expect(viewModel.rules.first.keyword, 'netflix inc');
      expect(viewModel.rules.first.categoryId, 3);
    });

    test('deleteRule calls repository and reloads', () async {
      mockRuleRepository.rules = [
        const RuleModel(id: 1, keyword: 'netflix', categoryId: 2),
      ];
      await viewModel.loadRules();

      final result = await viewModel.deleteRule(1);

      expect(result, true);
      expect(mockRuleRepository.deleteCalledWithId, 1);
      expect(viewModel.rules.length, 0);
    });

    test('applyRulesToAllTransactions bulk applies correctly', () async {
      mockRuleRepository.rules = [
        const RuleModel(
          id: 1,
          keyword: 'netflix',
          categoryId: 2,
        ), // Entertainment
        const RuleModel(id: 2, keyword: 'uber', categoryId: 3), // Transport
      ];

      final tx1 = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Netflix',
        categoryId: 1,
      ); // Old cat
      final tx2 = TransactionModel(
        id: 2,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Uber Trip',
        categoryId: 1,
      ); // Old cat
      final tx3 = TransactionModel(
        id: 3,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Unknown',
        categoryId: 1,
      ); // No match
      final tx4 = TransactionModel(
        id: 4,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Netflix',
        categoryId: 2,
      ); // Already correct

      mockTransactionRepository.transactions = [tx1, tx2, tx3, tx4];

      await viewModel.loadRules(); // Load rules into VM state

      final updatedCount = await viewModel.applyRulesToAllTransactions();

      expect(updatedCount, 2); // Only tx1 and tx2 should be updated
      expect(mockTransactionRepository.updateCalledCount, 2);
    });
  });
}
