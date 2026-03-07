import 'package:drift/drift.dart';
import 'categories_table.dart'; // Ensure CategoriesTable is imported

class RulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  IntColumn get categoryId => integer().references(CategoriesTable, #id)();
}
