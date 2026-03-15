import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/transactions/transaction_detail_screen.dart';
import 'package:provider/provider.dart';

class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository(this.transaction);

  TransactionModel? transaction;
  TransactionModel? lastUpdated;

  @override
  Future<TransactionModel?> getTransactionById(int id) async => transaction;

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    lastUpdated = transaction;
    this.transaction = transaction;
    return true;
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
  FakeCategoryRepository(this.categories);

  final List<CategoryModel> categories;

  @override
  Future<List<CategoryModel>> getAllCategories() async => categories;

  @override
  Future<CategoryModel?> getCategoryById(int id) async =>
      categories.where((category) => category.id == id).firstOrNull;

  @override
  Future<int> insertCategory(CategoryModel category) async => 1;

  @override
  Future<bool> updateCategory(CategoryModel category) async => true;

  @override
  Future<int> deleteCategory(int id) async => 1;

  @override
  Future<List<CategoryModel>> getDefaultCategories() async =>
      categories.where((category) => category.isDefault).toList();
}

void main() {
  testWidgets('renders transaction details and saves note updates', (
    tester,
  ) async {
    final transaction = TransactionModel(
      id: 100,
      date: DateTime(2026, 3, 15, 9, 30),
      amount: -500,
      source: 'HBL',
      type: 'card_charge',
      transactionId: 'txn-100',
      beneficiary: 'Grocer',
      subject: 'Raw message body',
      categoryId: 1,
      note: 'Old note',
      extra: '{"merchant":"Grocer","fee":10}',
      updatedAt: DateTime(2026, 3, 15, 9, 31),
      createdAt: DateTime(2026, 3, 15, 9, 30),
    );

    final transactionRepository = FakeTransactionRepository(transaction);
    final categoryRepository = FakeCategoryRepository(const [
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
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TransactionRepository>.value(value: transactionRepository),
          Provider<CategoryRepository>.value(value: categoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(
              transactionId: 100,
              isBottomSheet: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Grocer'), findsWidgets);
    expect(find.textContaining('txn-100'), findsOneWidget);
    expect(find.text('HBL'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Updated note');
    await tester.tap(find.byTooltip('Save note'));
    await tester.pumpAndSettle();

    expect(transactionRepository.lastUpdated?.note, 'Updated note');
    expect(find.text('merchant'), findsOneWidget);
    expect(find.text('Grocer'), findsWidgets);
  });
}
