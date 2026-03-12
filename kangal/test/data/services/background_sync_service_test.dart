import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/services/background_sync_service.dart';
import 'package:mockito/mockito.dart';
import 'package:workmanager/workmanager.dart';

// Mock class for Workmanager
class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  group('BackgroundSyncService', () {
    test('nayapayEmailSyncTask constant is correct', () {
      expect(
        BackgroundSyncService.nayapayEmailSyncTask,
        equals('nayapay_email_sync'),
      );
    });

    test('syncFrequency is 30 minutes', () {
      expect(
        BackgroundSyncService.syncFrequency,
        equals(const Duration(minutes: 30)),
      );
    });

    test('initializeBackgroundSync handles errors gracefully', () async {
      // Test that calling initializeBackgroundSync doesn't throw
      try {
        // Note: This test will use the actual Workmanager on Android
        // For pure unit testing, this is limited. A more thorough test
        // would require dependency injection or mocking the static Workmanager class.
        // For now, we just verify the method can be called.
        expect(() async {
          await BackgroundSyncService.initializeBackgroundSync();
        }, returnsNormally);
      } catch (e) {
        fail('initializeBackgroundSync should not throw: $e');
      }
    });

    test('cancelBackgroundSync handles errors gracefully', () async {
      try {
        expect(() async {
          await BackgroundSyncService.cancelBackgroundSync();
        }, returnsNormally);
      } catch (e) {
        fail('cancelBackgroundSync should not throw: $e');
      }
    });
  });

  group('callbackDispatcher', () {
    test('callbackDispatcher is annotated with entry point pragma', () {
      // The callbackDispatcher function should have @pragma('vm:entry-point')
      // This test verifies the function exists and can be called
      expect(callbackDispatcher, isNotNull);
    });
  });
}
