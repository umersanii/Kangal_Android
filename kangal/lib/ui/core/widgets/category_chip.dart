import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String emoji;
  final String name;

  const CategoryChip({super.key, required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Category: $name',
      child: Chip(
        label: Text('$emoji $name', style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
