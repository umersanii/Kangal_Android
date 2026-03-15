import 'package:workmanager/workmanager.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/repositories/email_import_repository_impl.dart';
import 'package:kangal/data/repositories/drift_transaction_repository.dart';
import 'package:kangal/data/repositories/drift_rule_repository.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:kangal/data/services/supabase_sync_service.dart';

/// Service to configure and manage background email sync tasks.
class BackgroundSyncService {
  static const String nayapayEmailSyncTask = 'nayapay_email_sync';
  static const String supabaseSyncTask = 'supabase_sync';
  static const Duration syncFrequency = Duration(minutes: 30);

  /// Initializes the Workmanager and registers the periodic email sync task.
  ///
  /// Call this once during app startup in main.dart.
  static Future<void> initializeBackgroundSync() async {
    try {
      await Workmanager().initialize(callbackDispatcher);

      // Register the periodic email sync task
      await Workmanager().registerPeriodicTask(
        nayapayEmailSyncTask,
        nayapayEmailSyncTask,
        tag: nayapayEmailSyncTask,
        frequency: syncFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      await Workmanager().registerPeriodicTask(
        supabaseSyncTask,
        supabaseSyncTask,
        tag: supabaseSyncTask,
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
      // Failed to initialize background sync
    }
  }

  /// Cancels all background sync tasks.
  ///
  /// Useful for cleanup or when user signs out.
  static Future<void> cancelBackgroundSync() async {
    try {
      await Workmanager().cancelByTag(nayapayEmailSyncTask);
      await Workmanager().cancelByTag(supabaseSyncTask);
    } catch (e) {
      // Failed to cancel background sync
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
    AppDatabase? db;
    try {
      db = AppDatabase();

      if (taskName == BackgroundSyncService.nayapayEmailSyncTask) {
        final transactionRepository = DriftTransactionRepository(
          db.transactionsDao,
        );
        final ruleRepository = DriftRuleRepository(db.rulesDao);
        final secureStorageService = SecureStorageService();
        final autoCategorisationService = AutoCategorisationService();

        final emailImportRepository = EmailImportRepositoryImpl(
          nayaPayEmailService: NayaPayEmailService(),
          transactionRepository: transactionRepository,
          ruleRepository: ruleRepository,
          secureStorageService: secureStorageService,
          autoCategorisationService: autoCategorisationService,
        );

        await emailImportRepository.importEmails();
        return true;
      }

      if (taskName == BackgroundSyncService.supabaseSyncTask) {
        final authService = SupabaseAuthService();
        final isAuthenticated = await authService.isAuthenticated();
        if (!isAuthenticated) {
          return true;
        }

        final syncService = SupabaseSyncService(
          transactionsDao: db.transactionsDao,
          categoriesDao: db.categoriesDao,
          rulesDao: db.rulesDao,
          syncLogDao: db.syncLogDao,
          authService: authService,
        );

        await syncService.syncAll();
        return true;
      }

      return false;
    } catch (e) {
      // Error in background sync task
      return false;
    } finally {
      await db?.close();
    }
  });
}
