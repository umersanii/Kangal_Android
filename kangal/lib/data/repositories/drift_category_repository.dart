import 'package:kangal/data/database/daos/categories_dao.dart';
import 'package:kangal/data/models/category_model.dart';
import 'category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  final CategoriesDao _dao;

  DriftCategoryRepository(this._dao);

  @override
  Future<List<Category>> getAllCategories() => _dao.getAllCategories();

  @override
  Future<Category?> getCategoryById(int id) => _dao.getCategoryById(id);

  @override
  Future<int> insertCategory(Category category) =>
      _dao.insertCategory(category);

  @override
  Future<bool> updateCategory(Category category) =>
      _dao.updateCategory(category);

  @override
  Future<int> deleteCategory(int id) => _dao.deleteCategory(id);

  @override
  Future<List<Category>> getDefaultCategories() => _dao.getDefaultCategories();
}
