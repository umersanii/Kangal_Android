import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/rules_table.dart';
import 'tables/sync_log_table.dart';
import 'daos/transactions_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/rules_dao.dart';
import 'daos/sync_log_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TransactionsTable, CategoriesTable, RulesTable, SyncLogTable],
  daos: [TransactionsDao, CategoriesDao, RulesDao, SyncLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'kangal.db');
    return NativeDatabase(File(dbPath));
  });
}
