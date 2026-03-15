import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/core/widgets/period_selector.dart';
import 'package:kangal/ui/dashboard/dashboard_view_model.dart';

void main() {
  testWidgets('PeriodSelector renders correctly and calls onChanged', (
    WidgetTester tester,
  ) async {
    PeriodPreset? selectedPreset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSelector(
            current: PeriodPreset.thisMonth,
            onChanged: (preset) {
              selectedPreset = preset;
            },
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(4));
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Last Month'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);

    final thisMonthChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'This Month'),
    );
    expect(thisMonthChip.selected, isTrue);

    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();

    expect(selectedPreset, PeriodPreset.thisWeek);
  });
}
