import os
import glob

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if "FakeTransactionRepository" not in content:
        return

    # Add imports
    if "daily_spend.dart" not in content:
        content = "import 'package:kangal/data/models/daily_spend.dart';\n" + content
    if "category_spend.dart" not in content:
        content = "import 'package:kangal/data/models/category_spend.dart';\n" + content
        
    if "getDailySpend" not in content:
        # Find exactly the last throw UnimplementedError(); } in FakeTransactionRepository
        # Actually, let's just append to the end of the fake class.
        # Find where FakeTransactionRepository ends.
        
        # This is simple: just find "class _FakeTransactionRepository implements TransactionRepository {"
        # and then find the corresponding closing brace.
        pass

    # A simpler way: we know getSummary is there
    if "getSummary(" in content and "getDailySpend" not in content:
        content = content.replace("  Future<TransactionSummary> getSummary(DateTime startDate, DateTime endDate) {\n    throw UnimplementedError();\n  }", "  Future<TransactionSummary> getSummary(DateTime startDate, DateTime endDate) {\n    throw UnimplementedError();\n  }\n\n  @override\n  Future<List<DailySpend>> getDailySpend(DateTime startDate, DateTime endDate) {\n    throw UnimplementedError();\n  }\n\n  @override\n  Future<List<CategorySpend>> getCategorySpend(DateTime startDate, DateTime endDate) {\n    throw UnimplementedError();\n  }")

    with open(filepath, 'w') as f:
        f.write(content)

for filepath in glob.glob("/home/sani/c0d3/Kangal_Android/kangal/test/data/repositories/*.dart"):
    fix_file(filepath)

