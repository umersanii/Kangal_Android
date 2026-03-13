import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';

void main() {
  late AutoCategorisationService service;

  setUp(() {
    service = AutoCategorisationService();
  });

  group('AutoCategorisationService', () {
    test('returns null when transaction beneficiary is null', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: null,
      );
      final rules = [const RuleModel(id: 1, keyword: 'spotify', categoryId: 2)];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, isNull);
    });

    test('returns correct categoryId for exact match', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Netflix',
      );
      final rules = [const RuleModel(id: 1, keyword: 'Netflix', categoryId: 3)];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, 3);
    });

    test('returns correct categoryId for case-insensitive match', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'UBER TRIP',
      );
      final rules = [const RuleModel(id: 1, keyword: 'uber', categoryId: 4)];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, 4);
    });

    test('returns correct categoryId for partial match', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'McDonalds Branch 123',
      );
      final rules = [
        const RuleModel(id: 1, keyword: 'mcdonalds', categoryId: 5),
      ];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, 5);
    });

    test('returns null when no rule matches', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Unknown Merchant',
      );
      final rules = [const RuleModel(id: 1, keyword: 'spotify', categoryId: 2)];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, isNull);
    });

    test('returns first matching rule', () {
      final transaction = TransactionModel(
        id: 1,
        date: DateTime.now(),
        amount: -100,
        source: 'Cash',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        beneficiary: 'Foodpanda Islamabad',
      );
      final rules = [
        const RuleModel(id: 1, keyword: 'foodpanda', categoryId: 6),
        const RuleModel(id: 2, keyword: 'food', categoryId: 7),
      ];

      final result = service.applyCategoryRules(transaction, rules);

      expect(result, 6);
    });
  });
}
