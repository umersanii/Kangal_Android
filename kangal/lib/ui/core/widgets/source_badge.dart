import 'package:flutter/material.dart';
import 'package:kangal/ui/core/theme.dart';

class SourceBadge extends StatelessWidget {
  final String source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final color = switch (source.toLowerCase()) {
      'hbl' => AppTheme.hblSourceColor,
      'nayapay' => AppTheme.nayaPaySourceColor,
      _ => AppTheme.cashSourceColor,
    };

    return Semantics(
      label: 'Source: $source',
      child: Chip(
        label: Text(
          source,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        side: BorderSide.none,
      ),
    );
  }
}
