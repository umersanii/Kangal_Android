import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/ui/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/models/category_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = transaction.amount < 0 
        ? AppTheme.expenseColor 
        : AppTheme.incomeColor;
        
    final amountFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final amountText = amountFormatter.format(transaction.amount.abs());
    
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final dateText = dateFormatter.format(transaction.date);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.beneficiary ?? 'Unknown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${transaction.amount > 0 ? '+' : '-'}$amountText',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SourceBadge(source: transaction.source),
                  const SizedBox(width: 8),
                  if (transaction.categoryId != null)
                    FutureBuilder<CategoryModel?>(
                      future: context.read<CategoryRepository>().getCategoryById(transaction.categoryId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        return _CategoryChip(category: snapshot.data!);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (source.toLowerCase()) {
      case 'hbl':
        badgeColor = AppTheme.hblSourceColor;
        break;
      case 'nayapay':
        badgeColor = AppTheme.nayaPaySourceColor;
        break;
      default:
        badgeColor = AppTheme.cashSourceColor;
    }

    return Chip(
      label: Text(
        source,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: badgeColor,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${category.emoji} ${category.name}',
        style: const TextStyle(fontSize: 12),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
