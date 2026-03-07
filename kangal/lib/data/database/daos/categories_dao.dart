import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';
import '../../models/category_model.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await select(categoriesTable).get();
    return rows
        .map(
          (row) => CategoryModel(
            id: row.id,
            name: row.name,
            emoji: row.emoji,
            color: row.color,
            isDefault: row.isDefault,
          ),
        )
        .toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final row = await (select(
      categoriesTable,
    )..where((c) => c.id.equals(id))).getSingleOrNull();

    if (row == null) return null;

    return CategoryModel(
      id: row.id,
      name: row.name,
      emoji: row.emoji,
      color: row.color,
      isDefault: row.isDefault,
    );
  }

  Future<int> insertCategory(CategoryModel category) {
    return into(categoriesTable).insert(
      CategoriesTableCompanion(
        name: Value(category.name),
        emoji: Value(category.emoji),
        color: Value(category.color),
        isDefault: Value(category.isDefault),
      ),
    );
  }

  Future<bool> updateCategory(CategoryModel category) {
    return update(categoriesTable).replace(
      CategoriesTableCompanion(
        id: Value(category.id),
        name: Value(category.name),
        emoji: Value(category.emoji),
        color: Value(category.color),
        isDefault: Value(category.isDefault),
      ),
    );
  }

  Future<int> deleteCategory(int id) =>
      (delete(categoriesTable)..where((c) => c.id.equals(id))).go();

  Future<List<CategoryModel>> getDefaultCategories() async {
    final rows = await (select(
      categoriesTable,
    )..where((c) => c.isDefault.equals(true))).get();

    return rows
        .map(
          (row) => CategoryModel(
            id: row.id,
            name: row.name,
            emoji: row.emoji,
            color: row.color,
            isDefault: row.isDefault,
          ),
        )
        .toList();
  }
}
