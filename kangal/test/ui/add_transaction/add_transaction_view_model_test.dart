import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:kangal/ui/add_transaction/add_transaction_view_model.dart';

class FakeTransactionRepository implements TransactionRepository {
  TransactionModel? insertedTransaction;

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    insertedTransaction = transaction;
    return 1;
  }

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
  Future<List<TransactionModel>> searchTransactions(String query) async => [];

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async => true;

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
  ) async {
    return TransactionSummary(
      totalSpent: 0,
      totalIncome: 0,
      netBalance: 0,
      transactionCount: 0,
    );
  }

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async => 0;
}

class FakeCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = [];

  @override
  Future<List<CategoryModel>> getAllCategories() async => categories;

  @override
  Future<CategoryModel?> getCategoryById(int id) async => null;

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

class FakeRuleRepository implements RuleRepository {
  List<RuleModel> rules = [];

  @override
  Future<List<RuleModel>> getAllRules() async => rules;

  @override
  Future<RuleModel?> getRuleById(int id) async => null;

  @override
  Future<int> insertRule(RuleModel rule) async => 1;

  @override
  Future<bool> updateRule(RuleModel rule) async => true;

  @override
  Future<int> deleteRule(int id) async => 1;
}

void main() {
  late FakeTransactionRepository transactionRepository;
  late FakeCategoryRepository categoryRepository;
  late FakeRuleRepository ruleRepository;
  late AddTransactionViewModel viewModel;

  setUp(() {
    transactionRepository = FakeTransactionRepository();
    categoryRepository = FakeCategoryRepository();
    ruleRepository = FakeRuleRepository();

    viewModel = AddTransactionViewModel(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
      autoCategorisationService: AutoCategorisationService(),
      ruleRepository: ruleRepository,
    );
  });

  test('valid save succeeds', () async {
    viewModel.amount = 1500;
    viewModel.selectedDate = DateTime.now().subtract(
      const Duration(minutes: 1),
    );
    viewModel.beneficiary = 'Manual entry';
    viewModel.source = 'Cash';
    viewModel.categoryId = 2;

    final result = await viewModel.saveTransaction();

    expect(result, true);
    expect(transactionRepository.insertedTransaction, isNotNull);
    expect(transactionRepository.insertedTransaction!.type, 'manual');
    expect(transactionRepository.insertedTransaction!.source, 'Cash');
    expect(transactionRepository.insertedTransaction!.categoryId, 2);
  });

  test('zero amount fails', () async {
    viewModel.amount = 0;
    viewModel.selectedDate = DateTime.now().subtract(
      const Duration(minutes: 1),
    );

    final result = await viewModel.saveTransaction();

    expect(result, false);
    expect(viewModel.errorMessage, contains('non-zero'));
    expect(transactionRepository.insertedTransaction, isNull);
  });

  test('future date fails', () async {
    viewModel.amount = 500;
    viewModel.selectedDate = DateTime.now().add(const Duration(days: 1));

    final result = await viewModel.saveTransaction();

    expect(result, false);
    expect(viewModel.errorMessage, contains('future'));
    expect(transactionRepository.insertedTransaction, isNull);
  });

  test('auto-categorisation applies when no category selected', () async {
    viewModel.amount = -300;
    viewModel.selectedDate = DateTime.now().subtract(
      const Duration(minutes: 1),
    );
    viewModel.beneficiary = 'Google YouTube';
    viewModel.categoryId = null;
    ruleRepository.rules = const [
      RuleModel(id: 1, keyword: 'youtube', categoryId: 9),
    ];

    final result = await viewModel.saveTransaction();

    expect(result, true);
    expect(transactionRepository.insertedTransaction, isNotNull);
    expect(transactionRepository.insertedTransaction!.categoryId, 9);
  });
}
