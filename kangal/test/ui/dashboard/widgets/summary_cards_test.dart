import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/core/theme.dart';
import 'package:kangal/ui/dashboard/widgets/summary_cards.dart';
import 'package:intl/intl.dart';

void main() {
  Widget buildTestWidget(TransactionSummary summary) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SummaryCards(summary: summary),
      ),
    );
  }

  testWidgets('SummaryCards renders correctly', (WidgetTester tester) async {
    final summary = TransactionSummary(
      totalSpent: 1500.0,
      totalIncome: 5000.0,
      netBalance: 3500.0,
      transactionCount: 12,
    );

    await tester.pumpWidget(buildTestWidget(summary));
    await tester.pumpAndSettle();

    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Verify titles
    expect(find.text('Total Spent'), findsOneWidget);
    expect(find.text('Total Income'), findsOneWidget);
    expect(find.text('Net Balance'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);

    // Verify values using same formatter to avoid platform/locale issues
    expect(find.text(currencyFormat.format(1500.0)), findsOneWidget);
    expect(find.text(currencyFormat.format(5000.0)), findsOneWidget);
    expect(find.text(currencyFormat.format(3500.0)), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('SummaryCards renders negative net balance correctly', (WidgetTester tester) async {
    final summary = TransactionSummary(
      totalSpent: 6000.0,
      totalIncome: 5000.0,
      netBalance: -1000.0,
      transactionCount: 15,
    );

    await tester.pumpWidget(buildTestWidget(summary));
    await tester.pumpAndSettle();

    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    expect(find.text(currencyFormat.format(-1000.0)), findsOneWidget);
  });
}
