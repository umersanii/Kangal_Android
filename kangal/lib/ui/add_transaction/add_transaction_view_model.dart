import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';

class AddTransactionViewModel extends ChangeNotifier {
  AddTransactionViewModel({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required AutoCategorisationService autoCategorisationService,
    required RuleRepository ruleRepository,
  }) : _transactionRepository = transactionRepository,
       _categoryRepository = categoryRepository,
       _autoCategorisationService = autoCategorisationService,
       _ruleRepository = ruleRepository;

  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final AutoCategorisationService _autoCategorisationService;
  final RuleRepository _ruleRepository;

  double? amount;
  DateTime selectedDate = DateTime.now();
  String? beneficiary;
  int? categoryId;
  String? note;
  String source = 'Cash';
  bool isSaving = false;
  String? errorMessage;
  List<CategoryModel> categories = [];

  void setSelectedDate(DateTime dateTime) {
    selectedDate = dateTime;
    notifyListeners();
  }

  void setSource(String value) {
    source = value;
    notifyListeners();
  }

  void setCategoryId(int? value) {
    categoryId = value;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      categories = await _categoryRepository.getAllCategories();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  Future<bool> saveTransaction() async {
    errorMessage = null;

    final amountValue = amount;
    if (amountValue == null || amountValue == 0) {
      errorMessage = 'Amount must be non-zero.';
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    if (selectedDate.isAfter(now)) {
      errorMessage = 'Date cannot be in the future.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    notifyListeners();

    try {
      var resolvedCategoryId = categoryId;
      final resolvedSource = source == 'Cash' ? 'Cash' : 'Other';

      if (resolvedCategoryId == null) {
        final rules = await _ruleRepository.getAllRules();
        final draftTransaction = TransactionModel(
          id: 0,
          date: selectedDate,
          amount: amountValue,
          source: resolvedSource,
          type: 'manual',
          transactionId: null,
          beneficiary: beneficiary,
          categoryId: null,
          note: note,
          updatedAt: now,
          createdAt: now,
        );
        resolvedCategoryId = _autoCategorisationService.applyCategoryRules(
          draftTransaction,
          rules,
        );
      }

      final transaction = TransactionModel(
        id: 0,
        date: selectedDate,
        amount: amountValue,
        source: resolvedSource,
        type: 'manual',
        transactionId: null,
        beneficiary: beneficiary,
        categoryId: resolvedCategoryId,
        note: note,
        updatedAt: now,
        createdAt: now,
      );

      await _transactionRepository.insertTransaction(transaction);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save transaction: $e';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
