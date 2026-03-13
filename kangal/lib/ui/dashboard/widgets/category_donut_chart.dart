import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/category_spend.dart';

class CategoryDonutChart extends StatelessWidget {
  final List<CategorySpend> data;

  const CategoryDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No categorical data available'));
    }

    final double total = data.fold(0, (sum, item) => sum + item.totalSpent);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((item) {
                // Ensure percentage adds up to 100 correctly, handling 0 edge case
                final double percentage = total > 0
                    ? (item.totalSpent / total) * 100
                    : 0;

                // Parse color from hex string if available
                Color sectionColor = Colors.grey;
                if (item.color != null && item.color!.isNotEmpty) {
                  try {
                    String hexColor = item.color!.replaceAll('#', '');
                    if (hexColor.length == 6) {
                      hexColor = 'FF$hexColor';
                    }
                    sectionColor = Color(int.parse(hexColor, radix: 16));
                  } catch (_) {
                    // Fallback to grey if parse fails
                  }
                }

                return PieChartSectionData(
                  color: sectionColor,
                  value: item.totalSpent,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: data.map((item) {
            Color legendColor = Colors.grey;
            if (item.color != null && item.color!.isNotEmpty) {
              try {
                String hexColor = item.color!.replaceAll('#', '');
                if (hexColor.length == 6) {
                  hexColor = 'FF$hexColor';
                }
                legendColor = Color(int.parse(hexColor, radix: 16));
              } catch (_) {}
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: legendColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('${item.emoji ?? ''} ${item.categoryName ?? 'Unknown'}'),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
