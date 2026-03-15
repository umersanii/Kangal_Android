import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/core/theme.dart';
import 'package:kangal/ui/core/widgets/source_badge.dart';

void main() {
  Widget buildWidget(String source) {
    return MaterialApp(
      home: Scaffold(body: SourceBadge(source: source)),
    );
  }

  testWidgets('shows source label text', (tester) async {
    await tester.pumpWidget(buildWidget('HBL'));

    expect(find.text('HBL'), findsOneWidget);
  });

  testWidgets('uses HBL green color', (tester) async {
    await tester.pumpWidget(buildWidget('HBL'));

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, AppTheme.hblSourceColor);
  });

  testWidgets('uses NayaPay purple color', (tester) async {
    await tester.pumpWidget(buildWidget('NayaPay'));

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, AppTheme.nayaPaySourceColor);
  });

  testWidgets('uses Cash grey color by default', (tester) async {
    await tester.pumpWidget(buildWidget('Cash'));

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, AppTheme.cashSourceColor);
  });
}
