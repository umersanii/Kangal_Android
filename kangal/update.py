import sys

p = '/home/sani/c0d3/Kangal_Android/plan/Plan.md'
content = open(p).read()

p1_orig = '| TASK-042 | Create `lib/ui/settings/rules/rules_screen.dart`: `ListView` of rule tiles — each showing keyword and target category name/emoji. FAB to add new rule. Add/edit dialog: `TextField` for keyword, `DropdownButton` for category selection. Delete with confirmation. Button: "Apply Rules to All Transactions" triggers bulk application with progress indicator and result snackbar showing count of recategorised transactions. Commit message: `feat: implement auto-categorisation rules management screen` | | |'
p1_new = p1_orig[:-5] + '✅ | 2026-03-13 |'

p2_orig = '| TASK-043 | Create `lib/data/services/auto_categorisation_service.dart`: class `AutoCategorisationService` with method `applyCategoryRules(TransactionModel transaction, List<RuleModel> rules) → int?` — iterates rules, performs case-insensitive `contains` match of `rule.keyword` against `transaction.beneficiary`. Returns first matching `rule.categoryId`, or null if no match. This service is used by `SmsImportRepository` and `EmailImportRepository` during import. Commit message: `feat: add auto-categorisation service for keyword-based rule matching` | | |'
p2_new = p2_orig[:-5] + '✅ | 2026-03-13 |'

content = content.replace(p1_orig, p1_new)
content = content.replace(p2_orig, p2_new)
open(p, 'w').write(content)
