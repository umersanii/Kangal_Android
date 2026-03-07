import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kangal/data/repositories/drift_category_repository.dart';
import 'package:kangal/data/database/daos/categories_dao.dart';

class MockCategoriesDao extends Mock implements CategoriesDao {}

void main() {
  late MockCategoriesDao mockDao;
  late DriftCategoryRepository repository;

  setUp(() {
    mockDao = MockCategoriesDao();
    repository = DriftCategoryRepository(mockDao);
  });

  test('getAllCategories calls DAO method', () async {
    when(mockDao.getAllCategories()).thenAnswer((_) async => []);

    final result = await repository.getAllCategories();

    verify(mockDao.getAllCategories()).called(1);
    expect(result, isEmpty);
  });
}
