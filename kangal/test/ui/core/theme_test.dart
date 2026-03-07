import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/core/theme.dart';

void main() {
  group('AppTheme constants', () {
    test('defines expense and income colors', () {
      expect(AppTheme.expenseColor, const Color(0xFFE74C3C));
      expect(AppTheme.incomeColor, const Color(0xFF27AE60));
    });

    test('defines source badge colors', () {
      expect(AppTheme.hblSourceColor, const Color(0xFF006B3F));
      expect(AppTheme.nayaPaySourceColor, const Color(0xFF6C63FF));
      expect(AppTheme.cashSourceColor, const Color(0xFF95A5A6));
    });
  });

  group('AppTheme ThemeData', () {
    test('uses Material 3 for light and dark themes', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
      expect(lightTheme.colorScheme.brightness, Brightness.light);
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('meets minimum 4.5:1 contrast on key color pairs', () {
      final lightTheme = AppTheme.lightTheme;

      final primaryContrast = _contrastRatio(
        lightTheme.colorScheme.primary,
        lightTheme.colorScheme.onPrimary,
      );
      final surfaceContrast = _contrastRatio(
        lightTheme.colorScheme.surface,
        lightTheme.colorScheme.onSurface,
      );

      expect(primaryContrast, greaterThanOrEqualTo(4.5));
      expect(surfaceContrast, greaterThanOrEqualTo(4.5));
    });

    testWidgets('supports system text scaling', (tester) async {
      Future<Size> pumpAndGetSize(double scale) async {
        final key = GlobalKey();

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Scaling Test',
                    key: key,
                    style: AppTheme.lightTheme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        return tester.getSize(find.byKey(key));
      }

      final normalSize = await pumpAndGetSize(1.0);
      final scaledSize = await pumpAndGetSize(1.5);

      expect(scaledSize.height, greaterThan(normalSize.height));
      expect(scaledSize.width, greaterThan(normalSize.width));
    });
  });
}

double _contrastRatio(Color background, Color foreground) {
  final l1 = background.computeLuminance();
  final l2 = foreground.computeLuminance();

  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;

  return (lighter + 0.05) / (darker + 0.05);
}
