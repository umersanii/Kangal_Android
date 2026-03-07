import 'package:drift/drift.dart';

class RulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  IntColumn get categoryId =>
      integer().customConstraint('REFERENCES categories(id)')();
}
