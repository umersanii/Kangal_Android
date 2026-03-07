import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:drift/native.dart';

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/rules_table.dart';
import 'tables/sync_log_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TransactionsTable, CategoriesTable, RulesTable, SyncLogTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kangal.db'));
    return NativeDatabase(file);
  });
}
