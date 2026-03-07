import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kangal/routing/app_router.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRouter', () {
    testWidgets(
      'initial location is /onboarding if onboarding_complete is false',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_complete': false});

        final router = await AppRouter.createRouter();

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
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

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
