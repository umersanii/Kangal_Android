import 'package:kangal/data/database/daos/rules_dao.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'rule_repository.dart';

class DriftRuleRepository implements RuleRepository {
  final RulesDao _dao;

  DriftRuleRepository(this._dao);

  @override
  Future<List<Rule>> getAllRules() => _dao.getAllRules();

  @override
  Future<Rule?> getRuleById(int id) => _dao.getRuleById(id);

  @override
  Future<int> insertRule(Rule rule) => _dao.insertRule(rule);

  @override
  Future<bool> updateRule(Rule rule) => _dao.updateRule(rule);

  @override
  Future<int> deleteRule(int id) => _dao.deleteRule(id);
}
