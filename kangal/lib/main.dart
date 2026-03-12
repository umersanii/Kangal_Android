import 'package:flutter/material.dart';
import 'package:kangal/app.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/drift_category_repository.dart';
import 'package:kangal/data/repositories/drift_rule_repository.dart';
import 'package:kangal/data/repositories/drift_transaction_repository.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/email_import_repository_impl.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository_impl.dart';
import 'package:kangal/data/services/background_sync_service.dart';
import 'package:kangal/data/services/hbl_sms_service.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/sms_inbox_service.dart';
import 'package:kangal/data/services/sms_permission_service.dart';
import 'package:kangal/routing/app_router.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background sync service for email sync tasks
  await BackgroundSyncService.initializeBackgroundSync();

  final appDatabase = AppDatabase();
  final transactionRepository = DriftTransactionRepository(
    appDatabase.transactionsDao,
  );
  final categoryRepository = DriftCategoryRepository(appDatabase.categoriesDao);
  final ruleRepository = DriftRuleRepository(appDatabase.rulesDao);
  final router = await AppRouter.createRouter();

  // SMS-related services and import repository for HBL parsing
  final smsPermissionService = SmsPermissionService();
  final smsInboxService = SmsInboxService();
  final hblSmsService = HblSmsService();
  final smsImportRepository = SmsImportRepositoryImpl(
    smsInboxService: smsInboxService,
    hblSmsService: hblSmsService,
    transactionRepository: transactionRepository,
    ruleRepository: ruleRepository,
  );

  // Email-related services and import repository for NayaPay parsing
  final secureStorageService = SecureStorageService();
  final nayaPayEmailService = NayaPayEmailService();
  final emailImportRepository = EmailImportRepositoryImpl(
    nayaPayEmailService: nayaPayEmailService,
    transactionRepository: transactionRepository,
    ruleRepository: ruleRepository,
    secureStorageService: secureStorageService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: appDatabase),
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<RuleRepository>.value(value: ruleRepository),
        Provider<SmsPermissionService>.value(value: smsPermissionService),
        Provider<SmsInboxService>.value(value: smsInboxService),
        Provider<HblSmsService>.value(value: hblSmsService),
        Provider<SmsImportRepository>.value(value: smsImportRepository),
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<NayaPayEmailService>.value(value: nayaPayEmailService),
        Provider<EmailImportRepository>.value(value: emailImportRepository),
        Provider<BackgroundSyncService>.value(value: BackgroundSyncService()),
      ],
      child: KangalApp(router: router),
    ),
  );
}
