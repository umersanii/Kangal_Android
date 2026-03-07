import 'package:kangal/data/database/daos/rules_dao.dart';
import 'package:kangal/data/models/rule_model.dart';

abstract class RuleRepository {
  Future<List<Rule>> getAllRules();
  Future<Rule?> getRuleById(int id);
  Future<int> insertRule(Rule rule);
  Future<bool> updateRule(Rule rule);
  Future<int> deleteRule(int id);
}
