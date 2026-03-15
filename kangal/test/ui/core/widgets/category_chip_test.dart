import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/core/widgets/category_chip.dart';

void main() {
  testWidgets('renders emoji and category name in compact chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryChip(emoji: '🍔', name: 'Food'),
        ),
      ),
    );

    expect(find.text('🍔 Food'), findsOneWidget);

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.visualDensity, VisualDensity.compact);
  });
}
