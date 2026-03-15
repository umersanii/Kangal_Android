import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/date_range.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

class TransactionsViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  List<TransactionModel> transactions = [];
  bool isLoading = false;
  bool hasMore = true;
  int _offset = 0;
  String? searchQuery;
  String? sourceFilter;
  int? categoryFilter;
  DateRange? dateFilter;
  String? errorMessage;

  static const int _pageSize = 50;

  TransactionsViewModel(this._transactionRepository) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    errorMessage = null;
    isLoading = true;
    _offset = 0;
    notifyListeners();

    try {
      final results = await _transactionRepository.getFilteredTransactions(
        limit: _pageSize,
        offset: _offset,
        searchQuery: searchQuery,
        sourceFilter: sourceFilter,
        categoryFilter: categoryFilter,
        startDate: dateFilter?.start,
        endDate: dateFilter?.end,
      );

      transactions = results;
      _offset += results.length;
      hasMore = results.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load transactions. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final results = await _transactionRepository.getFilteredTransactions(
        limit: _pageSize,
        offset: _offset,
        searchQuery: searchQuery,
        sourceFilter: sourceFilter,
        categoryFilter: categoryFilter,
        startDate: dateFilter?.start,
        endDate: dateFilter?.end,
      );

      transactions = [...transactions, ...results];
      _offset += results.length;
      hasMore = results.length == _pageSize;
    } catch (_) {
      errorMessage = 'Failed to load more transactions.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    searchQuery = query;
    _offset = 0;
    loadTransactions();
  }

  void setSourceFilter(String? source) {
    sourceFilter = source;
    _offset = 0;
    loadTransactions();
  }

  void setCategoryFilter(int? categoryId) {
    categoryFilter = categoryId;
    _offset = 0;
    loadTransactions();
  }

  void setDateFilter(DateRange? range) {
    dateFilter = range;
    _offset = 0;
    loadTransactions();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
