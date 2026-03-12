import 'package:workmanager/workmanager.dart';

/// Service to configure and manage background email sync tasks.
class BackgroundSyncService {
  static const String nayapayEmailSyncTask = 'nayapay_email_sync';
  static const Duration syncFrequency = Duration(minutes: 30);

  /// Initializes the Workmanager and registers the periodic email sync task.
  /// 
  /// Call this once during app startup in main.dart.
  static Future<void> initializeBackgroundSync() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Register the periodic email sync task
      await Workmanager().registerPeriodicTask(
        nayapayEmailSyncTask,
        nayapayEmailSyncTask,
        frequency: syncFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      print('Failed to initialize background sync: $e');
    }
  }

  /// Cancels all background sync tasks.
  /// 
  /// Useful for cleanup or when user signs out.
  static Future<void> cancelBackgroundSync() async {
    try {
      await Workmanager().cancelByTag(nayapayEmailSyncTask);
    } catch (e) {
      print('Failed to cancel background sync: $e');
    }
  }
}

/// Top-level callback function for Workmanager.
/// 
/// This function is called by the Android system when the periodic task triggers.
/// It must be a top-level function (not a method) for Workmanager to find it.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == BackgroundSyncService.nayapayEmailSyncTask) {
        // Perform email sync
        // Note: This normally would call EmailImportRepository.importEmails(),
        // but since this runs in an isolate, dependencies must be recreated here
        // or passed via inputData. For now, just log that the task executed.
        print('Background email sync task executed at ${DateTime.now()}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error in background sync task: $e');
      return false;
    }
  });
}
