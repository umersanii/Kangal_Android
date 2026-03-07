import 'package:kangal/data/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel?> getCategoryById(int id);
  Future<int> insertCategory(CategoryModel category);
  Future<bool> updateCategory(CategoryModel category);
  Future<int> deleteCategory(int id);
  Future<List<CategoryModel>> getDefaultCategories();
}
