import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:kangal/ui/dashboard/dashboard_view_model.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/add_transaction/add_transaction_screen.dart';
import 'package:kangal/ui/dashboard/dashboard_screen.dart';
import 'package:kangal/ui/onboarding/onboarding_screen.dart';
import 'package:kangal/ui/settings/categories/categories_screen.dart';
import 'package:kangal/ui/settings/email_setup/email_setup_screen.dart';
import 'package:kangal/ui/settings/rules/rules_screen.dart';
import 'package:kangal/ui/settings/settings_screen.dart';
import 'package:kangal/ui/settings/supabase_auth_screen.dart';
import 'package:kangal/ui/transactions/transaction_detail_screen.dart';
import 'package:kangal/ui/transactions/transactions_screen.dart';

export 'package:kangal/ui/add_transaction/add_transaction_screen.dart';
export 'package:kangal/ui/dashboard/dashboard_screen.dart';
export 'package:kangal/ui/onboarding/onboarding_screen.dart';
export 'package:kangal/ui/settings/categories/categories_screen.dart';
export 'package:kangal/ui/settings/email_setup/email_setup_screen.dart';
export 'package:kangal/ui/settings/rules/rules_screen.dart';
export 'package:kangal/ui/settings/settings_screen.dart';
export 'package:kangal/ui/settings/supabase_auth_screen.dart';
export 'package:kangal/ui/transactions/transaction_detail_screen.dart';
export 'package:kangal/ui/transactions/transactions_screen.dart';

class AppRouter {
  static Future<GoRouter> createRouter() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    return GoRouter(
      initialLocation: onboardingComplete ? '/' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddTransactionScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return RootShellScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => ChangeNotifierProvider(
                    create: (context) => DashboardViewModel(
                      context.read<TransactionRepository>(),
                    ),
                    child: const DashboardScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transactions',
                  builder: (context, state) => const TransactionsScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final idParam = state.pathParameters['id'];
                        final transactionId = int.tryParse(idParam ?? '') ?? -1;
                        return TransactionDetailScreen(
                          transactionId: transactionId,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'email',
                      builder: (context, state) => const EmailSetupScreen(),
                    ),
                    GoRoute(
                      path: 'categories',
                      builder: (context, state) => const CategoriesScreen(),
                    ),
                    GoRoute(
                      path: 'rules',
                      builder: (context, state) => const RulesScreen(),
                    ),
                    GoRoute(
                      path: 'auth',
                      builder: (context, state) => const SupabaseAuthScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class RootShellScaffold extends StatelessWidget {
  const RootShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
