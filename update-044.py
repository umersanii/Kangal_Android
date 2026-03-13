import sys

p = '/home/sani/c0d3/Kangal_Android/plan/Plan.md'
content = open(p).read()

p1_orig = '| TASK-044 | Write unit tests: `test/data/services/auto_categorisation_service_test.dart` (keyword matching, case insensitivity, no match returns null, first match wins), `test/ui/settings/categories/categories_view_model_test.dart` (CRUD operations, default category deletion prevented, reassignment on delete), `test/ui/settings/rules/rules_view_model_test.dart` (CRUD operations, bulk apply). Commit message: `test: add unit tests for categories, rules, and auto-categorisation` | | |'
p1_new = p1_orig[:-5] + '✅ | 2026-03-13 |'

content = content.replace(p1_orig, p1_new)
open(p, 'w').write(content)
