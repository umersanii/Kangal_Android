import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';

class AutoCategorisationService {
  int? applyCategoryRules(TransactionModel transaction, List<RuleModel> rules) {
    if (transaction.beneficiary == null) return null;

    final beneficiaryLower = transaction.beneficiary!.toLowerCase();

    for (final rule in rules) {
      if (beneficiaryLower.contains(rule.keyword.toLowerCase())) {
        return rule.categoryId;
      }
    }

    return null;
  }
}
