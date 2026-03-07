import 'package:flutter/material.dart';
import 'package:kangal/app.dart';
import 'package:kangal/data/database/app_database.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/drift_category_repository.dart';
import 'package:kangal/data/repositories/drift_rule_repository.dart';
import 'package:kangal/data/repositories/drift_transaction_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/routing/app_router.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabase = AppDatabase();
  final transactionRepository = DriftTransactionRepository(
    appDatabase.transactionsDao,
  );
  final categoryRepository = DriftCategoryRepository(appDatabase.categoriesDao);
  final ruleRepository = DriftRuleRepository(appDatabase.rulesDao);
  final router = await AppRouter.createRouter();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: appDatabase),
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<RuleRepository>.value(value: ruleRepository),
      ],
      child: KangalApp(router: router),
    ),
  );
}
