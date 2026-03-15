import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

class RulesViewModel extends ChangeNotifier {
  final RuleRepository _ruleRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  RulesViewModel({
    required RuleRepository ruleRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  }) : _ruleRepository = ruleRepository,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository;

  List<RuleModel> _rules = [];
  List<RuleModel> get rules => _rules;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadRules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rules = await _ruleRepository.getAllRules();
      _categories = await _categoryRepository.getAllCategories();
    } catch (e) {
      _errorMessage = 'Failed to load rules: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRule(String keyword, int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRule = RuleModel(
        id: 0,
        keyword: keyword,
        categoryId: categoryId,
      );
      await _ruleRepository.insertRule(newRule);
      await loadRules();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRule(int id, String keyword, int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existing = _rules.firstWhere((r) => r.id == id);
      final updated = existing.copyWith(
        keyword: keyword,
        categoryId: categoryId,
      );
      await _ruleRepository.updateRule(updated);
      await loadRules();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRule(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ruleRepository.deleteRule(id);
      await loadRules();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> applyRulesToAllTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int updatedCount = 0;

    try {
      // Basic implementation for bulk apply
      // Iterates all transactions and applies keyword matching
      final transactions = await _transactionRepository.getAllTransactions(
        10000,
        0,
      );

      for (final tx in transactions) {
        if (tx.beneficiary == null || tx.beneficiary!.isEmpty) continue;

        final beneficiaryLower = tx.beneficiary!.toLowerCase();
        int? matchedCategoryId;

        for (final rule in _rules) {
          if (beneficiaryLower.contains(rule.keyword.toLowerCase())) {
            matchedCategoryId = rule.categoryId;
            break; // First match wins
          }
        }

        if (matchedCategoryId != null && matchedCategoryId != tx.categoryId) {
          final updatedTx = tx.copyWith(categoryId: matchedCategoryId);
          await _transactionRepository.updateTransaction(updatedTx);
          updatedCount++;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to apply rules: $e';
    } finally {
      // Reload rules shouldn't be strictly necessary but it resets isLoading
      _isLoading = false;
      notifyListeners();
    }

    return updatedCount;
  }
}
