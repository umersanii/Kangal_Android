import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository_impl.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/hbl_sms_service.dart';
import 'package:kangal/data/services/sms_inbox_service.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:telephony/telephony.dart';

SmsMessage _makeSms({
  required String address,
  required DateTime date,
  required String body,
}) {
  final map = <String, String>{
    'address': address,
    'body': body,
    'date': date.millisecondsSinceEpoch.toString(),
  };
  return SmsMessage.fromMap(map, [
    SmsColumn.ADDRESS,
    SmsColumn.BODY,
    SmsColumn.DATE,
  ]);
}

TransactionModel _makeTransaction({
  required String transactionId,
  String? beneficiary,
  int? categoryId,
}) {
  final now = DateTime.now();
  return TransactionModel(
    id: 0,
    remoteId: null,
    date: now,
    amount: -100,
    source: 'HBL',
    type: 'card_charge',
    transactionId: transactionId,
    beneficiary: beneficiary,
    subject: 'sample',
    categoryId: categoryId,
    note: null,
    extra: null,
    syncedAt: null,
    updatedAt: now,
    createdAt: now,
  );
}

class _FakeSmsInboxService extends SmsInboxService {
  _FakeSmsInboxService() : super(provider: _NoopSmsInboxProvider());

  List<SmsMessage> messages = [];
  void Function(SmsMessage)? listener;

  @override
  Future<List<SmsMessage>> getHblMessages({int daysBack = 90}) async =>
      messages;

  @override
  void listenForNewSms(void Function(SmsMessage p1) onMessage) {
    listener = onMessage;
  }
}

class _NoopSmsInboxProvider implements SmsInboxProvider {
  @override
  Future<List<SmsMessage>> getInboxSms({
    List<SmsColumn> columns = const [],
    SmsFilter? filter,
    List<OrderBy>? sortOrder,
  }) async {
    return [];
  }

  @override
  void listenIncomingSms({
    required MessageHandler onNewMessage,
    MessageHandler? onBackgroundMessage,
    bool listenInBackground = true,
  }) {}
}

class _FakeHblSmsService extends HblSmsService {
  final Map<String, TransactionModel?> _responses;

  _FakeHblSmsService(this._responses);

  @override
  TransactionModel? parseHblSms(String smsBody) => _responses[smsBody];
}

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<List<TransactionModel>> getFilteredTransactions({
    required int limit,
    required int offset,
    String? searchQuery,
    String? sourceFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  final List<TransactionModel> inserted = [];
  final Map<String, TransactionModel> _byTransactionId = {};

  @override
  Future<TransactionModel?> getTransactionByTransactionId(String txnId) async {
    return _byTransactionId[txnId];
  }

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    inserted.add(transaction);
    final txnId = transaction.transactionId;
    if (txnId != null && txnId.isNotEmpty) {
      _byTransactionId[txnId] = transaction;
    }
    return inserted.length;
  }

  @override
  Future<List<TransactionModel>> getAllTransactions(int limit, int offset) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionModel?> getTransactionById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateTransaction(TransactionModel transaction) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteTransaction(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionModel>> getTransactionsBySource(String source) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionModel>> searchTransactions(String query) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() {
    throw UnimplementedError();
  }

  @override
  Future<TransactionSummary> getSummary(DateTime startDate, DateTime endDate) {
    throw UnimplementedError();
  }

  @override
  Future<List<DailySpend>> getDailySpend(DateTime startDate, DateTime endDate) {
    throw UnimplementedError();
  }

  @override
  Future<List<CategorySpend>> getCategorySpend(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> reassignCategory(int oldCategoryId, int newCategoryId) async => 0;
}

class _FakeRuleRepository implements RuleRepository {
  _FakeRuleRepository(this.rules);

  final List<RuleModel> rules;

  @override
  Future<List<RuleModel>> getAllRules() async => rules;

  @override
  Future<RuleModel?> getRuleById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<int> insertRule(RuleModel rule) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateRule(RuleModel rule) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteRule(int id) {
    throw UnimplementedError();
  }
}

void main() {
  test('importing 3 unique messages inserts 3 transactions', () async {
    final inbox = _FakeSmsInboxService();
    inbox.messages = [
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'm1'),
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'm2'),
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'm3'),
    ];

    final parser = _FakeHblSmsService({
      'm1': _makeTransaction(transactionId: 'tx-1', beneficiary: 'Store A'),
      'm2': _makeTransaction(transactionId: 'tx-2', beneficiary: 'Store B'),
      'm3': _makeTransaction(transactionId: 'tx-3', beneficiary: 'Store C'),
    });
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);

    final repository = SmsImportRepositoryImpl(
      smsInboxService: inbox,
      hblSmsService: parser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
    );

    final count = await repository.importHistoricalSms();

    expect(count, 3);
    expect(transactions.inserted.length, 3);
  });

  test('duplicate transactionId is skipped', () async {
    final inbox = _FakeSmsInboxService();
    inbox.messages = [
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'd1'),
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'd2'),
    ];

    final parser = _FakeHblSmsService({
      'd1': _makeTransaction(transactionId: 'dup-1', beneficiary: 'Shop 1'),
      'd2': _makeTransaction(transactionId: 'dup-1', beneficiary: 'Shop 1'),
    });
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);

    final repository = SmsImportRepositoryImpl(
      smsInboxService: inbox,
      hblSmsService: parser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
    );

    final count = await repository.importHistoricalSms();

    expect(count, 1);
    expect(transactions.inserted.length, 1);
    expect(transactions.inserted.first.transactionId, 'dup-1');
  });

  test('auto-categorisation applies matching categoryId', () async {
    final inbox = _FakeSmsInboxService();
    inbox.messages = [
      _makeSms(address: 'HBL', date: DateTime.now(), body: 'rule-match'),
    ];

    final parser = _FakeHblSmsService({
      'rule-match': _makeTransaction(
        transactionId: 'rule-1',
        beneficiary: 'Super Mart Lahore',
      ),
    });
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([
      const RuleModel(id: 1, keyword: 'mart', categoryId: 42),
    ]);

    final repository = SmsImportRepositoryImpl(
      smsInboxService: inbox,
      hblSmsService: parser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
    );

    final count = await repository.importHistoricalSms();

    expect(count, 1);
    expect(transactions.inserted.length, 1);
    expect(transactions.inserted.first.categoryId, 42);
  });

  test('empty inbox returns 0', () async {
    final inbox = _FakeSmsInboxService()..messages = [];
    final parser = _FakeHblSmsService({});
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);

    final repository = SmsImportRepositoryImpl(
      smsInboxService: inbox,
      hblSmsService: parser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
    );

    final count = await repository.importHistoricalSms();

    expect(count, 0);
    expect(transactions.inserted, isEmpty);
  });
}
