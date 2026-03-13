import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/ui/dashboard/widgets/category_donut_chart.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  group('CategoryDonutChart', () {
    testWidgets('renders correctly with given CategorySpend data', (
      WidgetTester tester,
    ) async {
      final List<CategorySpend> mockData = [
        CategorySpend(
          categoryId: 1,
          categoryName: 'Food & Dining',
          emoji: '🍔',
          color: '#FF5733',
          totalSpent: 1000.0,
        ),
        CategorySpend(
          categoryId: 2,
          categoryName: 'Transport',
          emoji: '🚗',
          color: '#3498DB',
          totalSpent: 500.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDonutChart(data: mockData)),
        ),
      );

      // Verify that the chart renders
      expect(find.byType(PieChart), findsOneWidget);

      // Verify legends render correctly
      expect(find.text('🍔 Food & Dining'), findsOneWidget);
      expect(find.text('🚗 Transport'), findsOneWidget);
    });

    testWidgets('renders empty state when data is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CategoryDonutChart(data: [])),
        ),
      );

      // Verify empty text is shown
      expect(find.text('No categorical data available'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });
  });
}
