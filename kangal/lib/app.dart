import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kangal/ui/core/theme.dart';

class KangalApp extends StatelessWidget {
  const KangalApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kangal',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
