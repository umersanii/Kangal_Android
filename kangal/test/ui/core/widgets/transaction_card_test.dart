import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/core/widgets/transaction_card.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:provider/provider.dart';

class FakeCategoryRepository implements CategoryRepository {
  final Map<int, CategoryModel> _categories = {};

  void setupCategory(CategoryModel category) {
    _categories[category.id] = category;
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Future<CategoryModel?> getCategoryById(int id) async => _categories[id];

  @override
  Future<int> deleteCategory(int id) async => 1;

  @override
  Future<List<CategoryModel>> getDefaultCategories() async => [];

  @override
  Future<int> insertCategory(CategoryModel category) async => 1;

  @override
  Future<bool> updateCategory(CategoryModel category) async => true;
}

void main() {
  late FakeCategoryRepository mockCategoryRepo;

  setUp(() {
    mockCategoryRepo = FakeCategoryRepository();
  });

  Widget buildTestableWidget(TransactionModel transaction) {
    return MultiProvider(
      providers: [Provider<CategoryRepository>.value(value: mockCategoryRepo)],
      child: MaterialApp(
        home: Scaffold(
          body: TransactionCard(transaction: transaction, onTap: () {}),
        ),
      ),
    );
  }

  testWidgets('displays correct text, amount, and source badge', (
    tester,
  ) async {
    final transaction = TransactionModel(
      id: 1,
      date: DateTime(2026, 3, 15, 14, 30),
      amount: -1500,
      source: 'NayaPay',
      beneficiary: 'Supermarket',
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestableWidget(transaction));
    await tester.pumpAndSettle();

    expect(find.text('Supermarket'), findsWidgets);
    expect(find.text('-Rs. 1,500.00'), findsOneWidget);
    expect(find.text('15 Mar 2026, 02:30 PM'), findsOneWidget);
    expect(find.text('NayaPay'), findsOneWidget);
  });

  testWidgets('displays category chip if categoryId is present', (
    tester,
  ) async {
    final transaction = TransactionModel(
      id: 2,
      date: DateTime.now(),
      amount: -50,
      source: 'HBL',
      categoryId: 10,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final mockCategory = CategoryModel(
      id: 10,
      name: 'Food',
      emoji: '🍔',
      color: '#FF5733',
      isDefault: true,
    );

    mockCategoryRepo.setupCategory(mockCategory);

    await tester.pumpWidget(buildTestableWidget(transaction));
    await tester.pumpAndSettle();

    expect(find.text('🍔 Food'), findsOneWidget);
  });

  testWidgets('triggers onTap callback', (tester) async {
    bool tapped = false;
    final transaction = TransactionModel(
      id: 3,
      date: DateTime.now(),
      amount: 100,
      source: 'Cash',
      beneficiary: 'Tap Target',
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CategoryRepository>.value(value: mockCategoryRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: transaction,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap Target'));
    expect(tapped, isTrue);
  });
}
