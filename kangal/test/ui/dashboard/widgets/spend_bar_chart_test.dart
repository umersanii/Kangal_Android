import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/ui/dashboard/widgets/spend_bar_chart.dart';
import 'package:kangal/ui/core/theme.dart';

void main() {
  Widget createWidgetUnderTest(List<DailySpend> dailySpend) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: SpendBarChart(dailySpend: dailySpend)),
    );
  }

  testWidgets('SpendBarChart displays empty state message when data is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest([]));

    expect(find.text('No spending data for this period'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('SpendBarChart displays bar chart with data', (
    WidgetTester tester,
  ) async {
    final dailySpend = [
      DailySpend(date: DateTime(2023, 10, 1), totalSpent: 1500),
      DailySpend(date: DateTime(2023, 10, 2), totalSpent: 300),
      DailySpend(date: DateTime(2023, 10, 3), totalSpent: 50.5),
    ];

    await tester.pumpWidget(createWidgetUnderTest(dailySpend));

    // Verify chart is shown
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('No spending data for this period'), findsNothing);

    // Can't easily test standard chart painting text this way without
    // exact rendered text coords, but we can verify BarChart is present.
  });
}
