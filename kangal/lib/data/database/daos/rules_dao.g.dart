// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules_dao.dart';

// ignore_for_file: type=lint
mixin _$RulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTableTable get categoriesTable => attachedDatabase.categoriesTable;
  $RulesTableTable get rulesTable => attachedDatabase.rulesTable;
  RulesDaoManager get managers => RulesDaoManager(this);
}

class RulesDaoManager {
  final _$RulesDaoMixin _db;
  RulesDaoManager(this._db);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(
        _db.attachedDatabase,
        _db.categoriesTable,
      );
  $$RulesTableTableTableManager get rulesTable =>
      $$RulesTableTableTableManager(_db.attachedDatabase, _db.rulesTable);
}
