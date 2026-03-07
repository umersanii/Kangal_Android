import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color expenseColor = Color(0xFFE74C3C);
  static const Color incomeColor = Color(0xFF27AE60);

  static const Color hblSourceColor = Color(0xFF006B3F);
  static const Color nayaPaySourceColor = Color(0xFF6C63FF);
  static const Color cashSourceColor = Color(0xFF95A5A6);

  static const Color _seedColor = Color(0xFF2E7D32);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      contrastLevel: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      contrastLevel: 1,
    ),
  );
}
