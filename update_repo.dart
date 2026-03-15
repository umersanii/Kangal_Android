import 'dart:io';

void main() {
  final repoFile = File('kangal/lib/data/repositories/transaction_repository.dart');
  String repoContent = repoFile.readAsStringSync();
  repoContent = repoContent.replaceFirst(
    'Future<List<TransactionModel>> getAllTransactions(int limit, int offset);',
    '''Future<List<TransactionModel>> getAllTransactions(int limit, int offset);
  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  });'''
  );
  repoFile.writeAsStringSync(repoContent);

  final driftRepoFile = File('kangal/lib/data/repositories/drift_transaction_repository.dart');
  String driftContent = driftRepoFile.readAsStringSync();
  driftContent = driftContent.replaceFirst(
    '''  @override
  Future<List<TransactionModel>> getAllTransactions(int limit, int offset) =>
      _dao.getAllTransactions(limit, offset);''',
    '''  @override
  Future<List<TransactionModel>> getAllTransactions(int limit, int offset) =>
      _dao.getAllTransactions(limit, offset);

  @override
  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => _dao.getFilteredTransactions(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        sourceFilter: sourceFilter,
        categoryFilter: categoryFilter,
        startDate: startDate,
        endDate: endDate,
      );'''
  );
  driftRepoFile.writeAsStringSync(driftContent);
}
