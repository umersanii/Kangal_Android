import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/ui/transactions/transactions_view_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<TransactionRepository>()])
import 'transactions_view_model_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepository;
  late TransactionsViewModel viewModel;

  setUp(() {
    mockRepository = MockTransactionRepository();
    // Default mock response
    when(
      mockRepository.getFilteredTransactions(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        searchQuery: anyNamed('searchQuery'),
        sourceFilter: anyNamed('sourceFilter'),
        categoryFilter: anyNamed('categoryFilter'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ),
    ).thenAnswer((_) async => []);
  });

  TransactionModel createMockTransaction(int id) {
    return TransactionModel(
      id: id,
      date: DateTime.now(),
      amount: -100,
      source: 'Cash',
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  test('loadTransactions initializes properly and loads data', () async {
    final txs = List.generate(50, (i) => createMockTransaction(i));
    when(
      mockRepository.getFilteredTransactions(
        limit: 50,
        offset: 0,
        searchQuery: null,
        sourceFilter: null,
        categoryFilter: null,
        startDate: null,
        endDate: null,
      ),
    ).thenAnswer((_) async => txs);

    viewModel = TransactionsViewModel(mockRepository);

    // allow the constructor's async call to finish
    await Future.microtask(() {});

    expect(viewModel.isLoading, false);
    expect(viewModel.transactions.length, 50);
    expect(viewModel.hasMore, true);
  });

  test('loadMore appends data and updates offset', () async {
    final page1 = List.generate(50, (i) => createMockTransaction(i));
    final page2 = List.generate(20, (i) => createMockTransaction(i + 50));

    when(
      mockRepository.getFilteredTransactions(
        limit: 50,
        offset: 0,
        searchQuery: null,
        sourceFilter: null,
        categoryFilter: null,
        startDate: null,
        endDate: null,
      ),
    ).thenAnswer((_) async => page1);

    viewModel = TransactionsViewModel(mockRepository);
    await Future.microtask(() {});

    expect(viewModel.transactions.length, 50);

    when(
      mockRepository.getFilteredTransactions(
        limit: 50,
        offset: 50,
        searchQuery: null,
        sourceFilter: null,
        categoryFilter: null,
        startDate: null,
        endDate: null,
      ),
    ).thenAnswer((_) async => page2);

    await viewModel.loadMore();

    expect(viewModel.transactions.length, 70);
    expect(viewModel.hasMore, false); // Less than 50 items returned
  });

  test('filters reset offset and reload data', () async {
    viewModel = TransactionsViewModel(mockRepository);
    await Future.microtask(() {});

    when(
      mockRepository.getFilteredTransactions(
        limit: 50,
        offset: 0,
        searchQuery: 'food',
        sourceFilter: null,
        categoryFilter: null,
        startDate: null,
        endDate: null,
      ),
    ).thenAnswer((_) async => [createMockTransaction(1)]);

    viewModel.setSearchQuery('food');
    await Future.microtask(() {});

    expect(viewModel.searchQuery, 'food');
    verify(
      mockRepository.getFilteredTransactions(
        limit: 50,
        offset: 0,
        searchQuery: 'food',
        sourceFilter: null,
        categoryFilter: null,
        startDate: null,
        endDate: null,
      ),
    ).called(1);
  });
}
