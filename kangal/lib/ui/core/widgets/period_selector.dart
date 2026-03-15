import 'package:flutter/material.dart';
import 'package:kangal/ui/dashboard/dashboard_view_model.dart';

class PeriodSelector extends StatelessWidget {
  final PeriodPreset current;
  final ValueChanged<PeriodPreset> onChanged;

  const PeriodSelector({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChip(context, PeriodPreset.thisWeek, 'This Week'),
          const SizedBox(width: 8),
          _buildChip(context, PeriodPreset.thisMonth, 'This Month'),
          const SizedBox(width: 8),
          _buildChip(context, PeriodPreset.lastMonth, 'Last Month'),
          const SizedBox(width: 8),
          _buildChip(context, PeriodPreset.allTime, 'All Time'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, PeriodPreset preset, String label) {
    return Semantics(
      button: true,
      label: 'Select period: $label',
      child: ChoiceChip(
        tooltip: 'Select $label period',
        label: Text(label),
        selected: current == preset,
        onSelected: (selected) {
          if (selected) {
            onChanged(preset);
          }
        },
      ),
    );
  }
}
