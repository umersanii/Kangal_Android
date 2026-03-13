import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/settings/rules/rules_view_model.dart';

import 'rules_view_model_test.mocks.dart';

@GenerateMocks([RuleRepository, CategoryRepository, TransactionRepository])
void main() {
  late MockRuleRepository mockRuleRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockTransactionRepository mockTransactionRepo;
  late RulesViewModel viewModel;

  setUp(() {
    mockRuleRepo = MockRuleRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockTransactionRepo = MockTransactionRepository();

    viewModel = RulesViewModel(
      ruleRepository: mockRuleRepo,
      categoryRepository: mockCategoryRepo,
      transactionRepository: mockTransactionRepo,
    );
  });

  final sampleRules = [
    const RuleModel(id: 1, keyword: 'netflix', categoryId: 2),
  ];

  final sampleCategories = [
    const CategoryModel(id: 1, name: 'Food', emoji: '🍔', color: '#000000', isDefault: true),
    const CategoryModel(id: 2, name: 'Entertainment', emoji: '🎮', color: '#000000', isDefault: true),
  ];

  test('loadRules sets rules and categories on success', () async {
    when(mockRuleRepo.getAllRules()).thenAnswer((_) async => sampleRules);
    when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => sampleCategories);

    await viewModel.loadRules();

    expect(viewModel.rules, sampleRules);
    expect(viewModel.categories, sampleCategories);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('addRule inserts rule and reloads', () async {
    when(mockRuleRepo.getAllRules()).thenAnswer((_) async => sampleRules);
    when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => sampleCategories);
    when(mockRuleRepo.insertRule(any)).thenAnswer((_) async => 2);

    final result = await viewModel.addRule('spotify', 2);

    expect(result, isTrue);
    verify(mockRuleRepo.insertRule(any)).called(1);
    verify(mockRuleRepo.getAllRules()).called(1);
  });

  test('updateRule updates rule and reloads', () async {
    when(mockRuleRepo.getAllRules()).thenAnswer((_) async => sampleRules);
    when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => sampleCategories);
    when(mockRuleRepo.updateRule(any)).thenAnswer((_) async => true);

    await viewModel.loadRules(); // Load first so the existing rule is there.
    
    final result = await viewModel.updateRule(1, 'netflix updated', 2);

    expect(result, isTrue);
    verify(mockRuleRepo.updateRule(any)).called(1);
  });
  
  test('deleteRule deletes rule and reloads', () async {
    when(mockRuleRepo.getAllRules()).thenAnswer((_) async => sampleRules);
    when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => sampleCategories);
    when(mockRuleRepo.deleteRule(1)).thenAnswer((_) async => 1);

    final result = await viewModel.deleteRule(1);

    expect(result, isTrue);
    verify(mockRuleRepo.deleteRule(1)).called(1);
  });

  test('applyRulesToAllTransactions matches keyword to beneficiary and updates transaction', () async {
    when(mockRuleRepo.getAllRules()).thenAnswer((_) async => sampleRules);
    when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => sampleCategories);

    final tx1 = TransactionModel(
      id: 1,
      date: DateTime.now(),
      amount: -100,
      source: 'HBL',
      beneficiary: 'Netflix Subscription',
      categoryId: null, // should match rule 1 -> cat 2
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final tx2 = TransactionModel(
      id: 2,
      date: DateTime.now(),
      amount: -50,
      source: 'HBL',
      beneficiary: 'Random Store',
      categoryId: null, // should NOT match rule
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(mockTransactionRepo.getAllTransactions(any, any))
        .thenAnswer((_) async => [tx1, tx2]);

    when(mockTransactionRepo.updateTransaction(any)).thenAnswer((_) async => true);

    await viewModel.loadRules(); // Ensure rules are loaded
    final updateCount = await viewModel.applyRulesToAllTransactions();

    expect(updateCount, 1);
    
    final verification = verify(mockTransactionRepo.updateTransaction(captureAny));
    verification.called(1);
    
    final updatedTx = verification.captured.first as TransactionModel;
    expect(updatedTx.id, 1);
    expect(updatedTx.categoryId, 2);
  });
}
