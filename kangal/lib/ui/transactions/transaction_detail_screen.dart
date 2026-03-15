import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/core/theme.dart';
import 'package:kangal/ui/core/utils/currency_formatter.dart';
import 'package:kangal/ui/core/widgets/source_badge.dart';
import 'package:kangal/ui/transactions/transaction_detail_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;
  final bool isBottomSheet;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.isBottomSheet = false,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final TransactionDetailViewModel _viewModel;
  late final TextEditingController _noteController;
  bool _didSeedNote = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _viewModel = TransactionDetailViewModel(
      transactionRepository: context.read<TransactionRepository>(),
      categoryRepository: context.read<CategoryRepository>(),
    );
    _viewModel.loadTransaction(widget.transactionId);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onDeletePressed() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final deleted = await _viewModel.deleteTransaction();
    if (!mounted) {
      return;
    }

    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete transaction')),
    );
  }

  Widget _buildExtraSection(String? extra) {
    if (extra == null || extra.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? jsonMap;
    try {
      final decoded = jsonDecode(extra);
      if (decoded is Map<String, dynamic>) {
        jsonMap = decoded;
      }
    } catch (_) {}

    if (jsonMap == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Extra', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(extra),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Extra', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...jsonMap.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<TransactionDetailViewModel>(
      builder: (context, viewModel, child) {
        final errorMessage = viewModel.errorMessage;
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
            viewModel.clearError();
          });
        }

        final transaction = viewModel.transaction;

        if (viewModel.isLoading && transaction == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transaction == null) {
          return const Center(child: Text('Transaction not found.'));
        }

        if (!_didSeedNote) {
          _noteController.text = transaction.note ?? '';
          _didSeedNote = true;
        }

        final signedAmount =
            '${transaction.amount >= 0 ? '+' : '-'}${formatPkr(transaction.amount.abs())}';
        final amountColor = transaction.amount < 0
            ? AppTheme.expenseColor
            : AppTheme.incomeColor;
        final dateText = DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format(transaction.date);

        final content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signedAmount,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                transaction.beneficiary ?? 'Unknown beneficiary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(dateText, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SourceBadge(source: transaction.source),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: transaction.categoryId,
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
                  if (value != null) {
                    viewModel.updateCategory(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Text('Type: ${transaction.type ?? 'N/A'}'),
              const SizedBox(height: 4),
              Text('Transaction ID: ${transaction.transactionId ?? 'N/A'}'),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Raw Subject / SMS Body'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(transaction.subject ?? 'N/A'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  suffixIcon: IconButton(
                    onPressed: () => viewModel.updateNote(_noteController.text),
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Save note',
                  ),
                ),
                maxLines: 3,
              ),
              _buildExtraSection(transaction.extra),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: viewModel.isDeleting ? null : _onDeletePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: viewModel.isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Delete Transaction'),
                ),
              ),
            ],
          ),
        );

        if (!widget.isBottomSheet) {
          return content;
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(child: content),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: widget.isBottomSheet
          ? Material(
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: _buildBody(),
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Transaction Detail')),
              body: _buildBody(),
            ),
    );
  }
}
