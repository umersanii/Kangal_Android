import 'package:flutter/material.dart';
import 'package:kangal/data/models/date_range.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/ui/core/widgets/setup_banner.dart';
import 'package:kangal/ui/core/widgets/transaction_card.dart';
import 'package:kangal/ui/transactions/transaction_detail_screen.dart';
import 'package:kangal/ui/transactions/transactions_view_model.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          TransactionsViewModel(context.read<TransactionRepository>()),
      child: const _TransactionsScreenBody(),
    );
  }
}

enum _DatePreset { today, thisWeek, thisMonth, custom }

class _TransactionsScreenBody extends StatefulWidget {
  const _TransactionsScreenBody();

  @override
  State<_TransactionsScreenBody> createState() =>
      _TransactionsScreenBodyState();
}

class _TransactionsScreenBodyState extends State<_TransactionsScreenBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  _DatePreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<TransactionsViewModel>().loadMore();
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    if (pickedRange == null || !mounted) return;

    setState(() {
      _selectedPreset = _DatePreset.custom;
    });

    context.read<TransactionsViewModel>().setDateFilter(
      DateRange(
        start: DateTime(
          pickedRange.start.year,
          pickedRange.start.month,
          pickedRange.start.day,
        ),
        end: DateTime(
          pickedRange.end.year,
          pickedRange.end.month,
          pickedRange.end.day,
          23,
          59,
          59,
        ),
      ),
    );
  }

  void _setDatePreset(_DatePreset preset) {
    final now = DateTime.now();
    if (preset == _DatePreset.custom) {
      _pickCustomDateRange();
      return;
    }

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final range = switch (preset) {
      _DatePreset.today => DateRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      _DatePreset.thisWeek => DateRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      _DatePreset.thisMonth => DateRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      _ => DateRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    };

    setState(() {
      _selectedPreset = preset;
    });
    context.read<TransactionsViewModel>().setDateFilter(range);
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
    });

    if (!_showSearch) {
      _searchController.clear();
      context.read<TransactionsViewModel>().setSearchQuery(null);
    }
  }

  Future<void> _openTransactionDetail(int transactionId) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionDetailScreen(
        transactionId: transactionId,
        isBottomSheet: true,
      ),
    );

    if (deleted == true && mounted) {
      await context.read<TransactionsViewModel>().loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsViewModel>(
      builder: (context, viewModel, child) {
        final errorMessage = viewModel.errorMessage;
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
            viewModel.clearError();
          });
        }

        final isInitialLoading =
            viewModel.isLoading && viewModel.transactions.isEmpty;
        final isLoadingMore =
            viewModel.isLoading && viewModel.transactions.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: _showSearch
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search transactions',
                      border: InputBorder.none,
                    ),
                    onChanged: viewModel.setSearchQuery,
                  )
                : const Text('Transactions'),
            actions: [
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                tooltip: _showSearch ? 'Close search' : 'Search',
              ),
            ],
          ),
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SetupBanner(),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    FilterChip(
                      tooltip: 'Filter all sources',
                      label: const Text('All'),
                      selected: viewModel.sourceFilter == null,
                      onSelected: (_) => viewModel.setSourceFilter(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      tooltip: 'Filter HBL transactions',
                      label: const Text('HBL'),
                      selected: viewModel.sourceFilter == 'HBL',
                      onSelected: (_) => viewModel.setSourceFilter('HBL'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      tooltip: 'Filter NayaPay transactions',
                      label: const Text('NayaPay'),
                      selected: viewModel.sourceFilter == 'NayaPay',
                      onSelected: (_) => viewModel.setSourceFilter('NayaPay'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      tooltip: 'Filter Cash transactions',
                      label: const Text('Cash'),
                      selected: viewModel.sourceFilter == 'Cash',
                      onSelected: (_) => viewModel.setSourceFilter('Cash'),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Today'),
                      selected: _selectedPreset == _DatePreset.today,
                      onSelected: (_) => _setDatePreset(_DatePreset.today),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This Week'),
                      selected: _selectedPreset == _DatePreset.thisWeek,
                      onSelected: (_) => _setDatePreset(_DatePreset.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This Month'),
                      selected: _selectedPreset == _DatePreset.thisMonth,
                      onSelected: (_) => _setDatePreset(_DatePreset.thisMonth),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Custom'),
                      selected: _selectedPreset == _DatePreset.custom,
                      onSelected: (_) => _setDatePreset(_DatePreset.custom),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isInitialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.transactions.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : RefreshIndicator(
                        onRefresh: viewModel.loadTransactions,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: viewModel.transactions.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= viewModel.transactions.length) {
                              return isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox(height: 16);
                            }

                            final transaction = viewModel.transactions[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: TransactionCard(
                                transaction: transaction,
                                onTap: () =>
                                    _openTransactionDetail(transaction.id),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
