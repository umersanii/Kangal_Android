import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(AppDatabase db) : super(db);

  Future<List<Category>> getAllCategories() => select(categoriesTable).get();

  Future<Category?> getCategoryById(int id) => (select(categoriesTable)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(Insertable<Category> companion) => into(categoriesTable).insert(companion);

  Future<bool> updateCategory(Insertable<Category> companion) => update(categoriesTable).replace(companion);

  Future<int> deleteCategory(int id) => (delete(categoriesTable)..where((c) => c.id.equals(id))).go();

  Future<List<Category>> getDefaultCategories() => (select(categoriesTable)..where((c) => c.isDefault.equals(true))).get();
}