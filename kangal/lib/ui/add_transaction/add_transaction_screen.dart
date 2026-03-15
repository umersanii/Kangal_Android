import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:kangal/ui/add_transaction/add_transaction_view_model.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late final AddTransactionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AddTransactionViewModel(
      transactionRepository: context.read<TransactionRepository>(),
      categoryRepository: context.read<CategoryRepository>(),
      autoCategorisationService: context.read<AutoCategorisationService>(),
      ruleRepository: context.read<RuleRepository>(),
    );
    _viewModel.loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryController.dispose();
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _viewModel.selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_viewModel.selectedDate),
    );

    if (pickedTime == null || !mounted) return;

    _viewModel.setSelectedDate(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the form errors.')),
      );
      return;
    }

    _viewModel.amount = double.tryParse(_amountController.text.trim());
    _viewModel.beneficiary = _beneficiaryController.text.trim().isEmpty
        ? null
        : _beneficiaryController.text.trim();
    _viewModel.note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final success = await _viewModel.saveTransaction();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully.')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.errorMessage ?? 'Failed to save.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddTransactionViewModel>.value(
      value: _viewModel,
      child: Consumer<AddTransactionViewModel>(
        builder: (context, viewModel, child) {
          final dateLabel = DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(viewModel.selectedDate);

          return Scaffold(
            appBar: AppBar(title: const Text('Add Transaction')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed == 0) {
                        return 'Enter a non-zero amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Date & Time: $dateLabel'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryController,
                    decoration: const InputDecoration(
                      labelText: 'Beneficiary (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: viewModel.categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: viewModel.categories
                        .map(
                          (category) => DropdownMenuItem<int>(
                            value: category.id,
                            child: Text('${category.emoji} ${category.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      viewModel.setCategoryId(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'Cash', label: Text('Cash')),
                      ButtonSegment<String>(
                        value: 'Other',
                        label: Text('Other'),
                      ),
                    ],
                    selected: <String>{viewModel.source},
                    onSelectionChanged: (selection) {
                      viewModel.setSource(selection.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: viewModel.isSaving ? null : _onSavePressed,
                    child: viewModel.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
