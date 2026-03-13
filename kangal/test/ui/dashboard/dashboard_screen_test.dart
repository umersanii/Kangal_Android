import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:kangal/ui/dashboard/dashboard_screen.dart';
import 'package:kangal/ui/dashboard/dashboard_view_model.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/core/widgets/period_selector.dart';
import 'package:kangal/ui/dashboard/widgets/summary_cards.dart';
import 'package:kangal/ui/dashboard/widgets/spend_bar_chart.dart';
import 'package:kangal/ui/dashboard/widgets/category_donut_chart.dart';

import 'dashboard_screen_test.mocks.dart';

@GenerateMocks([DashboardViewModel])
void main() {
  late MockDashboardViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockDashboardViewModel();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<DashboardViewModel>.value(
        value: mockViewModel,
        child: const DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen', () {
    testWidgets('shows CircularProgressIndicator when loading and no data', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isLoading).thenReturn(true);
      when(mockViewModel.summary).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all components with data', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.selectedPreset).thenReturn(PeriodPreset.thisMonth);
      when(mockViewModel.summary).thenReturn(
        TransactionSummary(
          totalSpent: 1000.0,
          totalIncome: 2000.0,
          netBalance: 1000.0,
          transactionCount: 5,
        ),
      );
      when(
        mockViewModel.dailySpend,
      ).thenReturn([DailySpend(date: DateTime(2026, 3, 1), totalSpent: 100.0)]);
      when(mockViewModel.categorySpend).thenReturn([
        CategorySpend(
          categoryId: 1,
          categoryName: 'Food',
          emoji: '🍔',
          color: '#FF0000',
          totalSpent: 100.0,
        ),
      ]);

      await tester.pumpWidget(createWidgetUnderTest());

      // Assert PeriodSelector is shown
      expect(find.byType(PeriodSelector), findsOneWidget);

      // Assert SummaryCards are shown with 4 cards
      expect(find.byType(SummaryCards), findsOneWidget);
      expect(
        find.text('Rs. 1,000'),
        findsNWidgets(2),
      ); // total spent and net balance
      expect(find.text('Rs. 2,000'), findsOneWidget); // total income
      expect(find.text('5'), findsOneWidget); // transaction count

      // Assert Charts are shown
      expect(find.byType(SpendBarChart), findsOneWidget);
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.selectedPreset).thenReturn(PeriodPreset.thisMonth);
      when(mockViewModel.summary).thenReturn(
        TransactionSummary(
          totalSpent: 0.0,
          totalIncome: 0.0,
          netBalance: 0.0,
          transactionCount: 0,
        ),
      );
      when(mockViewModel.dailySpend).thenReturn([]);
      when(mockViewModel.categorySpend).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        find.text('No transactions found for this period.'),
        findsOneWidget,
      );
      expect(find.byType(SpendBarChart), findsNothing);
      expect(find.byType(CategoryDonutChart), findsNothing);
    });

    testWidgets('period selector triggers view model method call', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.selectedPreset).thenReturn(PeriodPreset.thisMonth);
      when(mockViewModel.summary).thenReturn(
        TransactionSummary(
          totalSpent: 0.0,
          totalIncome: 0.0,
          netBalance: 0.0,
          transactionCount: 0,
        ),
      );
      when(mockViewModel.dailySpend).thenReturn([]);
      when(mockViewModel.categorySpend).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on 'This Week' choice chip
      await tester.tap(find.text('This Week'));
      await tester.pump();

      verify(mockViewModel.selectPeriod(PeriodPreset.thisWeek)).called(1);
    });
  });
}
