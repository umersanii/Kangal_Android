import 'package:kangal/data/database/daos/categories_dao.dart';
import 'package:kangal/data/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);
  Future<int> insertCategory(Category category);
  Future<bool> updateCategory(Category category);
  Future<int> deleteCategory(int id);
  Future<List<Category>> getDefaultCategories();
}
