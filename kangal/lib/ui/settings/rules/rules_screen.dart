import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/ui/settings/rules/rules_view_model.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RulesViewModel>().loadRules();
    });
  }

  void _showRuleDialog(BuildContext context, {RuleModel? rule}) {
    final viewModel = context.read<RulesViewModel>();
    final isEditing = rule != null;
    final keywordController = TextEditingController(text: rule?.keyword ?? '');
    
    int? selectedCategory = rule?.categoryId;
    if (selectedCategory == null && viewModel.categories.isNotEmpty) {
      selectedCategory = viewModel.categories.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Rule' : 'Add Rule'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: keywordController,
                      decoration: const InputDecoration(labelText: 'Keyword'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a keyword';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: viewModel.categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text('${cat.emoji} ${cat.name}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Select a category';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final keyword = keywordController.text.trim();
                      bool success;
                      if (isEditing) {
                        success = await viewModel.updateRule(rule!.id, keyword, selectedCategory!);
                      } else {
                        success = await viewModel.addRule(keyword, selectedCategory!);
                      }

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, int ruleId) async {
    final viewModel = context.read<RulesViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await viewModel.deleteRule(ruleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules'),
      ),
      body: Consumer<RulesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.rules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Applying rules to all transactions...')),
                    );
                    final count = await viewModel.applyRulesToAllTransactions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Recategorised $count transactions')),
                      );
                    }
                  },
                  icon: const Icon(Icons.playlist_play),
                  label: const Text('Apply Rules to All Transactions'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              Expanded(
                child: viewModel.rules.isEmpty
                    ? const Center(
                        child: Text(
                          'No rules defined yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: viewModel.rules.length,
                        itemBuilder: (context, index) {
                          final rule = viewModel.rules[index];
                          final category = viewModel.categories
                              .where((c) => c.id == rule.categoryId)
                              .firstOrNull;

                          return ListTile(
                            title: Text('Keyword: "${rule.keyword}"'),
                            subtitle: category != null
                                ? Text('Target: ${category.emoji} ${category.name}')
                                : const Text('Unknown Category'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showRuleDialog(context, rule: rule),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDelete(context, rule.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
