import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kangal/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:mockito/mockito.dart';

class FakeTransactionRepository implements TransactionRepository {
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
  Future<List<DailySpend>> getDailySpend(DateTime start, DateTime end) async {
    return [];
  }

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRouter', () {
    testWidgets(
      'initial location is /onboarding if onboarding_complete is false',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_complete': false});

        final router = await AppRouter.createRouter();

        await tester.pumpWidget(
          Provider<TransactionRepository>.value(
            value: FakeTransactionRepository(),
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets('initial location is / if onboarding_complete is true', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});

      final router = await AppRouter.createRouter();

      await tester.pumpWidget(
        Provider<TransactionRepository>.value(
          value: FakeTransactionRepository(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });
  });
}
