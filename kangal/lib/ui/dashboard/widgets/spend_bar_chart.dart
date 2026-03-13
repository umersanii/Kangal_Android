import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/ui/core/theme.dart';

class SpendBarChart extends StatelessWidget {
  final List<DailySpend> dailySpend;

  const SpendBarChart({
    super.key,
    required this.dailySpend,
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpend.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    final maxY = dailySpend.fold<double>(
      0,
      (max, spend) => spend.totalSpent > max ? spend.totalSpent : max,
    );

    // Padding for max Y to give some top space
    final double topY = maxY > 0 ? maxY * 1.2 : 100;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: topY,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceContainerHighest,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final spend = dailySpend[groupIndex];
                  final formatter = NumberFormat.currency(
                    symbol: 'Rs. ',
                    decimalDigits: 0,
                  );
                  return BarTooltipItem(
                    '${DateFormat('MMM d').format(spend.date)}\n',
                    Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatter.format(spend.totalSpent),
                        style: TextStyle(
                          color: AppTheme.expenseColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= dailySpend.length) {
                      return const SizedBox.shrink();
                    }
                    
                    // Show fewer labels if there are many days
                    if (dailySpend.length > 14 && index % 3 != 0 && index != dailySpend.length - 1) {
                      return const SizedBox.shrink();
                    } else if (dailySpend.length > 7 && dailySpend.length <= 14 && index % 2 != 0 && index != dailySpend.length - 1) {
                      return const SizedBox.shrink();
                    }

                    final date = dailySpend[index].date;
                    final text = DateFormat('d MMM').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == topY) {
                      return const SizedBox.shrink();
                    }
                    
                    String text;
                    if (value >= 100000) {
                      text = '${(value / 1000).toStringAsFixed(0)}k';
                    } else if (value >= 1000) {
                      text = '${(value / 1000).toStringAsFixed(1)}k';
                      if (text.endsWith('.0k')) {
                        text = text.replaceAll('.0k', 'k');
                      }
                    } else {
                      text = value.toStringAsFixed(0);
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? (maxY / 4) : 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
                left: BorderSide.none,
                right: BorderSide.none,
                top: BorderSide.none,
              ),
            ),
            barGroups: dailySpend.asMap().entries.map((entry) {
              final index = entry.key;
              final spend = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: spend.totalSpent,
                    color: AppTheme.expenseColor,
                    width: dailySpend.length > 20 ? 8 : 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
