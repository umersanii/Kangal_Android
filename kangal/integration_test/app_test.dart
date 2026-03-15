import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kangal/app.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/sync_result.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/repositories/sync_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:kangal/routing/app_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Core user flow from onboarding to settings works', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': false});

    final transactionRepository = _FakeTransactionRepository();
    final categoryRepository = _FakeCategoryRepository();
    final ruleRepository = _FakeRuleRepository();
    final syncRepository = _FakeSyncRepository();
    final smsPermissionService = _FakeSmsPermissionService();
    final secureStorageService = _FakeSecureStorageService();
    final emailImportRepository = _FakeEmailImportRepository();
    final smsImportRepository = _FakeSmsImportRepository();
    final supabaseAuthService = _FakeSupabaseAuthService();

    final router = await AppRouter.createRouter();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TransactionRepository>.value(value: transactionRepository),
          Provider<CategoryRepository>.value(value: categoryRepository),
          Provider<RuleRepository>.value(value: ruleRepository),
          Provider<SyncRepository>.value(value: syncRepository),
          Provider<SmsPermissionService>.value(value: smsPermissionService),
          Provider<SecureStorageService>.value(value: secureStorageService),
          Provider<EmailImportRepository>.value(value: emailImportRepository),
          Provider<SmsImportRepository>.value(value: smsImportRepository),
          Provider<SupabaseAuthService>.value(value: supabaseAuthService),
          Provider<AutoCategorisationService>.value(
            value: AutoCategorisationService(),
          ),
        ],
        child: KangalApp(router: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Setup Kangal'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Go to Dashboard'), findsOneWidget);
    await tester.tap(find.text('Go to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('No transactions found for this period.'), findsOneWidget);

    router.go('/add');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '1200',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Beneficiary (optional)'),
      'Manual Groceries',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    router.go('/transactions');
    await tester.pumpAndSettle();

    expect(find.text('Manual Groceries'), findsOneWidget);

    await tester.tap(find.text('Manual Groceries'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('🍔 Food & Dining').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Groceries'), findsNothing);

    router.go('/settings');
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);
  });
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _transactions = [];
  int _nextId = 1;

  @override
  Future<int> deleteTransaction(int id) async {
    final before = _transactions.length;
    _transactions.removeWhere((tx) => tx.id == id);
    return before - _transactions.length;
  }

  @override
  Future<List<TransactionModel>> getAllTransactions(
    int limit,
    int offset,
  ) async {
    final sorted = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bucket = <int?, double>{};
    for (final tx in _transactions) {
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        continue;
      }
      if (tx.amount >= 0) {
        continue;
      }
      bucket[tx.categoryId] = (bucket[tx.categoryId] ?? 0) + tx.amount.abs();
    }
    return bucket.entries
        .map(
          (entry) => CategorySpend(
            categoryId: entry.key,
            categoryName: null,
            emoji: null,
            color: null,
            totalSpent: entry.value,
          ),
        )
        .toList();
  }

  @override
  Future<List<DailySpend>> getDailySpend(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bucket = <DateTime, double>{};
    for (final tx in _transactions) {
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        continue;
      }
      if (tx.amount >= 0) {
        continue;
      }
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      bucket[day] = (bucket[day] ?? 0) + tx.amount.abs();
    }
    final days = bucket.keys.toList()..sort();
    return days
        .map((day) => DailySpend(date: day, totalSpent: bucket[day]!))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Iterable<TransactionModel> result = _transactions;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final lower = searchQuery.toLowerCase();
      result = result.where((tx) {
        final beneficiary = tx.beneficiary?.toLowerCase() ?? '';
        final subject = tx.subject?.toLowerCase() ?? '';
        final note = tx.note?.toLowerCase() ?? '';
        return beneficiary.contains(lower) ||
            subject.contains(lower) ||
            note.contains(lower);
      });
    }

    if (sourceFilter != null && sourceFilter.isNotEmpty) {
      result = result.where((tx) => tx.source == sourceFilter);
    }

    if (categoryFilter != null) {
      result = result.where((tx) => tx.categoryId == categoryFilter);
    }

    if (startDate != null && endDate != null) {
      result = result.where(
        (tx) => !tx.date.isBefore(startDate) && !tx.date.isAfter(endDate),
      );
    }

    final sorted = result.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<TransactionSummary> getSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    double totalSpent = 0;
    double totalIncome = 0;
    int count = 0;

    for (final tx in _transactions) {
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        continue;
      }
      count++;
      if (tx.amount < 0) {
        totalSpent += tx.amount.abs();
      } else {
        totalIncome += tx.amount;
      }
    }

    return TransactionSummary(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      netBalance: totalIncome - totalSpent,
      transactionCount: count,
    );
  }

  @override
  Future<TransactionModel?> getTransactionById(int id) async {
    for (final transaction in _transactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<TransactionModel?> getTransactionByTransactionId(String txnId) async {
    for (final transaction in _transactions) {
      if (transaction.transactionId == txnId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _transactions
        .where((tx) => !tx.date.isBefore(start) && !tx.date.isAfter(end))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsBySource(String source) async {
    return _transactions.where((tx) => tx.source == source).toList();
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    return _transactions.where((tx) => tx.syncedAt == null).toList();
  }

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    _transactions.add(
      transaction.copyWith(
        id: _nextId++,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return _nextId - 1;
  }

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async {
    int affected = 0;
    for (var index = 0; index < _transactions.length; index++) {
      final tx = _transactions[index];
      if (tx.categoryId == oldCategoryId) {
        _transactions[index] = tx.copyWith(categoryId: newCategoryId);
        affected++;
      }
    }
    return affected;
  }

  @override
  Future<List<TransactionModel>> searchTransactions(String query) async {
    final lower = query.toLowerCase();
    return _transactions.where((tx) {
      return (tx.note ?? '').toLowerCase().contains(lower) ||
          (tx.subject ?? '').toLowerCase().contains(lower) ||
          (tx.beneficiary ?? '').toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index == -1) {
      return false;
    }
    _transactions[index] = transaction.copyWith(updatedAt: DateTime.now());
    return true;
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> _categories = [
    const CategoryModel(
      id: 1,
      name: 'Food & Dining',
      emoji: '🍔',
      color: '#FF5733',
      isDefault: true,
    ),
    const CategoryModel(
      id: 2,
      name: 'Other',
      emoji: '📦',
      color: '#95A5A6',
      isDefault: true,
    ),
  ];

  @override
  Future<int> deleteCategory(int id) async {
    final before = _categories.length;
    _categories.removeWhere((category) => category.id == id);
    return before - _categories.length;
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async => List.of(_categories);

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    for (final category in _categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  @override
  Future<List<CategoryModel>> getDefaultCategories() async {
    return _categories.where((category) => category.isDefault).toList();
  }

  @override
  Future<int> insertCategory(CategoryModel category) async {
    final nextId =
        (_categories.map((c) => c.id).fold(0, (a, b) => a > b ? a : b)) + 1;
    _categories.add(category.copyWith(id: nextId));
    return nextId;
  }

  @override
  Future<bool> updateCategory(CategoryModel category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      return false;
    }
    _categories[index] = category;
    return true;
  }
}

class _FakeRuleRepository implements RuleRepository {
  @override
  Future<int> deleteRule(int id) async => 1;

  @override
  Future<List<RuleModel>> getAllRules() async => const [];

  @override
  Future<RuleModel?> getRuleById(int id) async => null;

  @override
  Future<int> insertRule(RuleModel rule) async => 1;

  @override
  Future<bool> updateRule(RuleModel rule) async => true;
}

class _FakeSmsImportRepository implements SmsImportRepository {
  @override
  Future<int> importHistoricalSms() async => 0;

  @override
  void startRealtimeListener() {}
}

class _FakeEmailImportRepository implements EmailImportRepository {
  @override
  Future<int> importEmails() async => 0;

  @override
  Future<bool> testConnection() async => true;
}

class _FakeSmsPermissionService extends SmsPermissionService {
  _FakeSmsPermissionService();

  @override
  Future<bool> isSmsPermissionGranted() async => false;

  @override
  Future<bool> requestSmsPermission() async => false;
}

class _FakeSecureStorageService extends SecureStorageService {
  bool _hasEmailCredentials = false;

  @override
  Future<void> saveEmailCredentials(String email, String appPassword) async {
    _hasEmailCredentials = true;
  }

  @override
  Future<void> deleteEmailCredentials() async {
    _hasEmailCredentials = false;
  }

  @override
  Future<bool> hasEmailCredentials() async => _hasEmailCredentials;

  @override
  Future<({String email, String appPassword})?> getEmailCredentials() async {
    if (!_hasEmailCredentials) {
      return null;
    }
    return (email: 'test@example.com', appPassword: 'password');
  }

  @override
  Future<void> saveSupabaseToken(String token) async {}

  @override
  Future<String?> getSupabaseToken() async => null;

  @override
  Future<void> deleteSupabaseToken() async {}
}

class _FakeSyncRepository implements SyncRepository {
  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  Future<bool> hasUnsyncedChanges() async => false;

  @override
  Future<int> getUnsyncedChangesCount() async => 0;

  @override
  Future<SyncResult> syncNow() async {
    return const SyncResult(
      uploaded: 0,
      downloaded: 0,
      conflictsResolved: 0,
      success: true,
    );
  }
}

class _FakeSupabaseAuthService extends SupabaseAuthService {
  _FakeSupabaseAuthService()
    : super(secureStorageService: _FakeSecureStorageService());

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  String? getCurrentUserEmail() => null;
}
