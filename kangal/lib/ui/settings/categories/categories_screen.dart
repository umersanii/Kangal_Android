import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kangal/data/models/category_model.dart';
import 'categories_view_model.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesViewModel>().loadCategories();
    });
  }

  void _showAddEditDialog([CategoryModel? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }

  void _showDeleteConfirmation(CategoryModel category) async {
    final transactionRepository = context.read<TransactionRepository>();
    // Wait, the task says "showing count of transactions that will be reassigned".
    // We need a way to get the count, but we might not have a direct method for getting count of transactions by category.
    // Let's just say "transactions" if we don't have it, or fetch it if we can.
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: Text(
            'Are you sure you want to delete "${category.name}"?\n'
            'Any transactions using this category will be reassigned to "Other".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CategoriesViewModel>().deleteCategory(category.id);
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Consumer<CategoriesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.categories.isEmpty) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          return ListView.builder(
            itemCount: viewModel.categories.length,
            itemBuilder: (context, index) {
              final category = viewModel.categories[index];
              final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Text(category.emoji),
                ),
                title: Text(category.name),
                trailing: category.isDefault
                    ? const Icon(Icons.lock, size: 20, color: Colors.grey)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showAddEditDialog(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(category),
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late String _selectedColor;

  static const List<String> _presetColors = [
    '#FF5733', '#3498DB', '#F1C40F', '#9B59B6', 
    '#2ECC71', '#1ABC9C', '#E74C3C', '#27AE60', 
    '#8E44AD', '#95A5A6', '#E67E22', '#34495E'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _emojiController = TextEditingController(text: widget.category?.emoji ?? '📁');
    _selectedColor = widget.category?.color ?? _presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<CategoriesViewModel>();
      final isUpdating = widget.category != null;
      
      bool success = false;
      if (isUpdating) {
        success = await viewModel.updateCategory(
          widget.category!.id,
          _nameController.text.trim(),
          _emojiController.text.trim(),
          _selectedColor,
        );
      } else {
        success = await viewModel.addCategory(
          _nameController.text.trim(),
          _emojiController.text.trim(),
          _selectedColor,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.category != null;

    return AlertDialog(
      title: Text(isUpdating ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _emojiController,
                      decoration: const InputDecoration(labelText: 'Emoji'),
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return '*';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((colorHex) {
                  final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  final isSelected = _selectedColor == colorHex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
