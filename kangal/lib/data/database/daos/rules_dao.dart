import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rules_table.dart';

part 'rules_dao.g.dart';

@DriftAccessor(tables: [RulesTable])
class RulesDao extends DatabaseAccessor<AppDatabase> with _$RulesDaoMixin {
  RulesDao(AppDatabase db) : super(db);

  Future<List<Rule>> getAllRules() => select(rulesTable).get();

  Future<Rule?> getRuleById(int id) =>
      (select(rulesTable)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertRule(Insertable<Rule> companion) =>
      into(rulesTable).insert(companion);

  Future<bool> updateRule(Insertable<Rule> companion) =>
      update(rulesTable).replace(companion);

  Future<int> deleteRule(int id) =>
      (delete(rulesTable)..where((r) => r.id.equals(id))).go();
}
