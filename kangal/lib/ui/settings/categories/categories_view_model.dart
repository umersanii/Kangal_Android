import 'package:flutter/foundation.dart';
import 'package:kangal/data/models/category_model.dart';
import 'package:kangal/data/repositories/category_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';

class CategoriesViewModel extends ChangeNotifier {
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  CategoriesViewModel({
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  }) : _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getAllCategories();
    } catch (e) {
      _errorMessage = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(String name, String emoji, String color) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCategory = CategoryModel(
        id: 0, // Assigned by DB
        name: name,
        emoji: emoji,
        color: color,
        isDefault: false,
      );
      await _categoryRepository.insertCategory(newCategory);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(
    int id,
    String name,
    String emoji,
    String color,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingCategory = _categories.firstWhere((c) => c.id == id);

      final updatedCategory = existingCategory.copyWith(
        name: name,
        emoji: emoji,
        color: color,
      );

      await _categoryRepository.updateCategory(updatedCategory);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final copyOfCategories = List<CategoryModel>.from(_categories);
      final categoryToDelete = copyOfCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Category not found'),
      );

      if (categoryToDelete.isDefault) {
        throw Exception('Cannot delete a default category');
      }

      // Find "Other" category to reassign transactions to
      final otherCategory = copyOfCategories.firstWhere(
        (c) => c.name == 'Other' && c.isDefault,
        orElse: () => throw Exception(
          'Default "Other" category not found for reassignment',
        ),
      );

      await _transactionRepository.reassignCategory(id, otherCategory.id);
      await _categoryRepository.deleteCategory(id);

      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
