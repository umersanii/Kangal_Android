import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/database/daos/transactions_dao.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/models/category_model.dart';

void main() {
  late AppDatabase db;
  late TransactionsDao dao;

  setUp(() {
    db = AppDatabase(e: NativeDatabase.memory());
    dao = db.transactionsDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('getDailySpend groups and sums negative amounts correctly', () async {
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 3, 31);
    
    // Day 1
    await dao.insertTransaction(TransactionModel(
      id: 1, date: DateTime(2026, 3, 1, 10, 0), amount: -500, source: 'HBL',
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    await dao.insertTransaction(TransactionModel(
      id: 2, date: DateTime(2026, 3, 1, 14, 0), amount: -200, source: 'HBL',
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    // Day 2
    await dao.insertTransaction(TransactionModel(
      id: 3, date: DateTime(2026, 3, 2, 9, 0), amount: -300, source: 'HBL',
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    // Income (should be ignored)
    await dao.insertTransaction(TransactionModel(
      id: 4, date: DateTime(2026, 3, 2, 11, 0), amount: 1000, source: 'HBL', type: 'income',
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    // Outside range
    await dao.insertTransaction(TransactionModel(
      id: 5, date: DateTime(2026, 4, 1, 10, 0), amount: -100, source: 'HBL',
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));

    final dailySpend = await dao.getDailySpend(start, end);
    expect(dailySpend.length, 2);
    
    expect(dailySpend[0].date, DateTime(2026, 3, 1));
    expect(dailySpend[0].totalSpent, 700);

    expect(dailySpend[1].date, DateTime(2026, 3, 2));
    expect(dailySpend[1].totalSpent, 300);
  });

  test('getCategorySpend groups correctly', () async {
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 3, 31);

    await db.categoriesDao.insertCategory(CategoryModel(
      id: 1, name: 'Food', emoji: '🍔', color: '#FF0000', isDefault: true
    ));
    await db.categoriesDao.insertCategory(CategoryModel(
      id: 2, name: 'Transport', emoji: '🚗', color: '#00FF00', isDefault: true
    ));

    await dao.insertTransaction(TransactionModel(
      id: 1, date: DateTime(2026, 3, 2), amount: -150, source: 'HBL', categoryId: 1,
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    await dao.insertTransaction(TransactionModel(
      id: 2, date: DateTime(2026, 3, 3), amount: -50, source: 'HBL', categoryId: 1,
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    await dao.insertTransaction(TransactionModel(
      id: 3, date: DateTime(2026, 3, 4), amount: -300, source: 'HBL', categoryId: 2,
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    // null category
    await dao.insertTransaction(TransactionModel(
      id: 4, date: DateTime(2026, 3, 5), amount: -100, source: 'HBL', categoryId: null,
      updatedAt: DateTime.now(), createdAt: DateTime.now(),
    ));
    
    final categorySpend = await dao.getCategorySpend(start, end);
    expect(categorySpend.length, 3);
    
    // Should be sorted by totalSpent descending
    expect(categorySpend[0].categoryId, 2);
    expect(categorySpend[0].categoryName, 'Transport');
    expect(categorySpend[0].totalSpent, 300);

    expect(categorySpend[1].categoryId, 1);
    expect(categorySpend[1].categoryName, 'Food & Dining'); // seeded by db
    expect(categorySpend[1].totalSpent, 200);

    expect(categorySpend[2].categoryId, isNull);
    expect(categorySpend[2].categoryName, isNull);
    expect(categorySpend[2].totalSpent, 100);
  });
}
