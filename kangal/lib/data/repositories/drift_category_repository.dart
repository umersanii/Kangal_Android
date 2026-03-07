import 'package:kangal/data/database/daos/categories_dao.dart';
import 'package:kangal/data/models/category_model.dart';
import 'category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  final CategoriesDao _dao;

  DriftCategoryRepository(this._dao);

  @override
  Future<List<CategoryModel>> getAllCategories() => _dao.getAllCategories();

  @override
  Future<CategoryModel?> getCategoryById(int id) => _dao.getCategoryById(id);

  @override
  Future<int> insertCategory(CategoryModel category) =>
      _dao.insertCategory(category);

  @override
  Future<bool> updateCategory(CategoryModel category) =>
      _dao.updateCategory(category);

  @override
  Future<int> deleteCategory(int id) => _dao.deleteCategory(id);

  @override
  Future<List<CategoryModel>> getDefaultCategories() =>
      _dao.getDefaultCategories();

  Future<void> seedDefaultCategories() async {
    final existingCategories = await _dao.getAllCategories();
    if (existingCategories.isEmpty) {
      final defaultCategories = [
        CategoryModel(
          id: 0,
          name: 'Food & Dining',
          emoji: '🍔',
          color: '#FF5733',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Transport',
          emoji: '🚗',
          color: '#3498DB',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Utilities',
          emoji: '💡',
          color: '#F1C40F',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Shopping',
          emoji: '🛍️',
          color: '#9B59B6',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Health',
          emoji: '🏥',
          color: '#2ECC71',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Education',
          emoji: '📚',
          color: '#1ABC9C',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Entertainment',
          emoji: '🎮',
          color: '#E74C3C',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Salary/Income',
          emoji: '💰',
          color: '#27AE60',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Transfer',
          emoji: '🔄',
          color: '#8E44AD',
          isDefault: true,
        ),
        CategoryModel(
          id: 0,
          name: 'Other',
          emoji: '📦',
          color: '#95A5A6',
          isDefault: true,
        ),
      ];
      for (final category in defaultCategories) {
        await _dao.insertCategory(category);
      }
    }
  }
}
