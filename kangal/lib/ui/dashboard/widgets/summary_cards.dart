import 'package:flutter/material.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/core/theme.dart';
import 'package:kangal/ui/core/utils/currency_formatter.dart';

class SummaryCards extends StatelessWidget {
  final TransactionSummary summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildCard(
              context,
              width: cardWidth,
              title: 'Total Spent',
              amountText: formatPkr(summary.totalSpent),
              amountColor: AppTheme.expenseColor,
            ),
            _buildCard(
              context,
              width: cardWidth,
              title: 'Total Income',
              amountText: formatPkr(summary.totalIncome),
              amountColor: AppTheme.incomeColor,
            ),
            _buildCard(
              context,
              width: cardWidth,
              title: 'Net Balance',
              amountText: formatPkr(summary.netBalance),
              amountColor: summary.netBalance >= 0
                  ? AppTheme.incomeColor
                  : AppTheme.expenseColor,
            ),
            _buildCard(
              context,
              width: cardWidth,
              title: 'Transactions',
              amountText: summary.transactionCount.toString(),
              amountColor: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double width,
    required String title,
    required String amountText,
    required Color amountColor,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amountText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
