import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kangal/ui/core/widgets/period_selector.dart';
import 'package:kangal/ui/core/widgets/setup_banner.dart';
import 'package:kangal/ui/dashboard/dashboard_view_model.dart';
import 'package:kangal/ui/dashboard/widgets/category_donut_chart.dart';
import 'package:kangal/ui/dashboard/widgets/spend_bar_chart.dart';
import 'package:kangal/ui/dashboard/widgets/summary_cards.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SetupBanner(),
                PeriodSelector(
                  current: viewModel.selectedPreset,
                  onChanged: (preset) {
                    viewModel.selectPeriod(preset);
                  },
                ),
                const SizedBox(height: 16),
                if (viewModel.summary != null)
                  SummaryCards(summary: viewModel.summary!),
                const SizedBox(height: 24),
                if (viewModel.summary != null &&
                    viewModel.summary!.transactionCount == 0 &&
                    !viewModel.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No transactions found for this period.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Daily Spend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.dailySpend.isNotEmpty)
                    SpendBarChart(dailySpend: viewModel.dailySpend)
                  else
                    const SizedBox(
                      height: 200,
                      child: Center(child: Text('No spending data')),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Spending by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.categorySpend.isNotEmpty)
                    CategoryDonutChart(data: viewModel.categorySpend)
                  else
                    const SizedBox(
                      height: 200,
                      child: Center(child: Text('No category data')),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
