import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rules_table.dart';
import '../../models/rule_model.dart';

part 'rules_dao.g.dart';

@DriftAccessor(tables: [RulesTable])
class RulesDao extends DatabaseAccessor<AppDatabase> with _$RulesDaoMixin {
  RulesDao(super.db);

  Future<List<RuleModel>> getAllRules() async {
    final rows = await select(rulesTable).get();
    return rows
        .map(
          (row) => RuleModel(
            id: row.id,
            keyword: row.keyword,
            categoryId: row.categoryId,
          ),
        )
        .toList();
  }

  Future<RuleModel?> getRuleById(int id) async {
    final row = await (select(
      rulesTable,
    )..where((r) => r.id.equals(id))).getSingleOrNull();

    if (row == null) return null;

    return RuleModel(
      id: row.id,
      keyword: row.keyword,
      categoryId: row.categoryId,
    );
  }

  Future<int> insertRule(RuleModel rule) {
    return into(rulesTable).insert(
      RulesTableCompanion(
        keyword: Value(rule.keyword),
        categoryId: Value(rule.categoryId),
      ),
    );
  }

  Future<bool> updateRule(RuleModel rule) {
    return update(rulesTable).replace(
      RulesTableCompanion(
        id: Value(rule.id),
        keyword: Value(rule.keyword),
        categoryId: Value(rule.categoryId),
      ),
    );
  }

  Future<int> deleteRule(int id) =>
      (delete(rulesTable)..where((r) => r.id.equals(id))).go();
}
