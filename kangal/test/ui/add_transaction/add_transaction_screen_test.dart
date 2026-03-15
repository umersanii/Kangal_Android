import 'package:flutter/material.dart';
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
import 'package:kangal/ui/add_transaction/add_transaction_screen.dart';
import 'package:provider/provider.dart';

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
  @override
  Future<List<CategoryModel>> getAllCategories() async => const [
    CategoryModel(
      id: 1,
      name: 'Other',
      emoji: '📦',
      color: '#95A5A6',
      isDefault: true,
    ),
  ];

  @override
  Future<CategoryModel?> getCategoryById(int id) async => null;

  @override
  Future<int> insertCategory(CategoryModel category) async => 1;

  @override
  Future<bool> updateCategory(CategoryModel category) async => true;

  @override
  Future<int> deleteCategory(int id) async => 1;

  @override
  Future<List<CategoryModel>> getDefaultCategories() async => const [];
}

class FakeRuleRepository implements RuleRepository {
  @override
  Future<List<RuleModel>> getAllRules() async => const [];

  @override
  Future<RuleModel?> getRuleById(int id) async => null;

  @override
  Future<int> insertRule(RuleModel rule) async => 1;

  @override
  Future<bool> updateRule(RuleModel rule) async => true;

  @override
  Future<int> deleteRule(int id) async => 1;
}

Widget buildTestApp({required TransactionRepository transactionRepository}) {
  return MultiProvider(
    providers: [
      Provider<TransactionRepository>.value(value: transactionRepository),
      Provider<CategoryRepository>(create: (_) => FakeCategoryRepository()),
      Provider<RuleRepository>(create: (_) => FakeRuleRepository()),
      Provider<AutoCategorisationService>(
        create: (_) => AutoCategorisationService(),
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              child: const Text('Open Add'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('form renders all fields', (tester) async {
    final transactionRepository = FakeTransactionRepository();

    await tester.pumpWidget(
      buildTestApp(transactionRepository: transactionRepository),
    );
    await tester.tap(find.text('Open Add'));
    await tester.pumpAndSettle();

    expect(find.text('Amount'), findsOneWidget);
    expect(find.textContaining('Date & Time:'), findsOneWidget);
    expect(find.text('Beneficiary (optional)'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('validation messages appear for non-zero amount', (tester) async {
    final transactionRepository = FakeTransactionRepository();

    await tester.pumpWidget(
      buildTestApp(transactionRepository: transactionRepository),
    );
    await tester.tap(find.text('Open Add'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a non-zero amount'), findsOneWidget);
  });

  testWidgets('successful save navigates back', (tester) async {
    final transactionRepository = FakeTransactionRepository();

    await tester.pumpWidget(
      buildTestApp(transactionRepository: transactionRepository),
    );
    await tester.tap(find.text('Open Add'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '2500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Open Add'), findsOneWidget);
    expect(transactionRepository.insertedTransaction, isNotNull);
  });
}
