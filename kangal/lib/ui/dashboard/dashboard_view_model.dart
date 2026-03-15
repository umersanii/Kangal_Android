import 'package:kangal/data/models/date_range.dart';
import 'package:flutter/material.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

enum PeriodPreset { thisWeek, thisMonth, lastMonth, allTime }

class DashboardViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  TransactionSummary? summary;
  List<DailySpend> dailySpend = [];
  List<CategorySpend> categorySpend = [];
  DateRange selectedPeriod;
  PeriodPreset selectedPreset = PeriodPreset.thisMonth;
  bool isLoading = false;

  DashboardViewModel(this._transactionRepository)
    : selectedPeriod = _computeDateRange(PeriodPreset.thisMonth) {
    loadDashboardData();
  }

  void selectPeriod(PeriodPreset preset) {
    selectedPreset = preset;
    selectedPeriod = _computeDateRange(preset);
    loadDashboardData();
  }

  static DateRange _computeDateRange(PeriodPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case PeriodPreset.thisWeek:
        // Week starting Monday
        final daysSinceMonday = today.weekday - 1;
        final start = today.subtract(Duration(days: daysSinceMonday));
        final end = today
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        return DateRange(start: start, end: end);
      case PeriodPreset.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        // last day of month is start of next month minus 1 ms
        final nextMonth = today.month == 12 ? 1 : today.month + 1;
        final nextYear = today.month == 12 ? today.year + 1 : today.year;
        final end = DateTime(
          nextYear,
          nextMonth,
          1,
        ).subtract(const Duration(milliseconds: 1));
        return DateRange(start: start, end: end);
      case PeriodPreset.lastMonth:
        final lastMonth = today.month == 1 ? 12 : today.month - 1;
        final lastYear = today.month == 1 ? today.year - 1 : today.year;
        final start = DateTime(lastYear, lastMonth, 1);
        final end = DateTime(
          today.year,
          today.month,
          1,
        ).subtract(const Duration(milliseconds: 1));
        return DateRange(start: start, end: end);
      case PeriodPreset.allTime:
        final start = DateTime(2000, 1, 1);
        final end = DateTime(2100, 12, 31);
        return DateRange(start: start, end: end);
    }
  }

  Future<void> loadDashboardData() async {
    isLoading = true;
    notifyListeners();

    try {
      summary = await _transactionRepository.getSummary(
        selectedPeriod.start,
        selectedPeriod.end,
      );

      dailySpend = await _transactionRepository.getDailySpend(
        selectedPeriod.start,
        selectedPeriod.end,
      );

      categorySpend = await _transactionRepository.getCategorySpend(
        selectedPeriod.start,
        selectedPeriod.end,
      );
    } catch (e) {
      // Ignore unimplemented for now as TASK-031 implements them.
      if (e is! UnimplementedError) {
        rethrow;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
