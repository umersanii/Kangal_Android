import 'package:kangal/data/models/rule_model.dart';

abstract class RuleRepository {
  Future<List<RuleModel>> getAllRules();
  Future<RuleModel?> getRuleById(int id);
  Future<int> insertRule(RuleModel rule);
  Future<bool> updateRule(RuleModel rule);
  Future<int> deleteRule(int id);
}
