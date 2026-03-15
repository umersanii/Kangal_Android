import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:drift/native.dart';

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/rules_table.dart';
import 'tables/sync_log_table.dart';
import 'daos/transactions_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/rules_dao.dart';
import 'daos/sync_log_dao.dart';
import '../repositories/drift_category_repository.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TransactionsTable, CategoriesTable, RulesTable, SyncLogTable],
  daos: [TransactionsDao, CategoriesDao, RulesDao, SyncLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? e}) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createIndex(
          Index(
            'idx_transactions_date',
            'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions_table (date)',
          ),
        );
        await migrator.createIndex(
          Index(
            'idx_transactions_source',
            'CREATE INDEX IF NOT EXISTS idx_transactions_source ON transactions_table (source)',
          ),
        );
        await migrator.createIndex(
          Index(
            'idx_transactions_category_id',
            'CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions_table (category_id)',
          ),
        );
        await migrator.createIndex(
          Index(
            'idx_transactions_transaction_id',
            'CREATE INDEX IF NOT EXISTS idx_transactions_transaction_id ON transactions_table (transaction_id)',
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await seedInitialData();
    },
  );

  Future<void> seedInitialData() async {
    final categoryRepository = DriftCategoryRepository(CategoriesDao(this));
    await categoryRepository.seedDefaultCategories();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'kangal.db');
    return NativeDatabase(File(dbPath));
  });
}
