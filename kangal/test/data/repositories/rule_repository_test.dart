import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kangal/data/repositories/drift_rule_repository.dart';
import 'package:kangal/data/database/daos/rules_dao.dart';

class MockRulesDao extends Mock implements RulesDao {}

void main() {
  late MockRulesDao mockDao;
  late DriftRuleRepository repository;

  setUp(() {
    mockDao = MockRulesDao();
    repository = DriftRuleRepository(mockDao);
  });

  test('getAllRules calls DAO method', () async {
    when(mockDao.getAllRules()).thenAnswer((_) async => []);

    final result = await repository.getAllRules();

    verify(mockDao.getAllRules()).called(1);
    expect(result, isEmpty);
  });
}
