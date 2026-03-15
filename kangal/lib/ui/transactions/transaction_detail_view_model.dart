import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

class TransactionDetailViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  TransactionModel? transaction;
  List<CategoryModel> categories = [];
  bool isLoading = false;
  bool isDeleting = false;
  String? errorMessage;

  TransactionDetailViewModel({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  }) : _transactionRepository = transactionRepository,
       _categoryRepository = categoryRepository;

  Future<void> loadTransaction(int id) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _transactionRepository.getTransactionById(id),
        _categoryRepository.getAllCategories(),
      ]);

      transaction = results.first as TransactionModel?;
      categories = results.last as List<CategoryModel>;
    } catch (_) {
      errorMessage = 'Failed to load transaction details.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(int categoryId) async {
    final current = transaction;
    if (current == null) return false;

    errorMessage = null;
    try {
      final updated = current.copyWith(categoryId: categoryId);
      final success = await _transactionRepository.updateTransaction(updated);
      if (success) {
        transaction = updated;
        notifyListeners();
      }

      return success;
    } catch (_) {
      errorMessage = 'Failed to update category.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(String note) async {
    final current = transaction;
    if (current == null) return false;

    errorMessage = null;
    try {
      final updated = current.copyWith(note: note);
      final success = await _transactionRepository.updateTransaction(updated);
      if (success) {
        transaction = updated;
        notifyListeners();
      }

      return success;
    } catch (_) {
      errorMessage = 'Failed to update note.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction() async {
    final current = transaction;
    final id = current?.id;

    if (id == null) return false;

    errorMessage = null;
    isDeleting = true;
    notifyListeners();

    try {
      final deletedRows = await _transactionRepository.deleteTransaction(id);
      if (deletedRows > 0) {
        transaction = null;
        notifyListeners();
        return true;
      }
      errorMessage = 'Failed to delete transaction.';
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Failed to delete transaction.';
      notifyListeners();
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
