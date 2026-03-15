import 'package:kangal/data/models/category_spend.dart';
import 'package:kangal/data/models/daily_spend.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/email_import_repository_impl.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';

MimeMessage _createTestMessage({
  required String subject,
  required DateTime date,
  String? messageId,
}) {
  final message = MimeMessage();
  message.setHeader('subject', subject);
  message.setHeader('date', date.toUtc().toString());
  if (messageId != null) {
    message.setHeader('message-id', messageId);
  }
  return message;
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
    source: 'NayaPay',
    type: 'card_purchase',
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

class _FakeImapService implements ImapServiceInterface {
  List<MimeMessage> emails = [];
  bool connected = false;
  bool disconnected = false;
  bool connectionTestResult = true;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }

  @override
  Future<List<MimeMessage>> fetchNayaPayEmails({int daysBack = 90}) async =>
      emails;

  @override
  Future<bool> testConnection() async {
    return connectionTestResult;
  }
}

class _FakeNayaPayEmailService extends NayaPayEmailService {
  final Map<String, TransactionModel?> _responses;

  _FakeNayaPayEmailService(this._responses);

  @override
  TransactionModel? parseEmail(MimeMessage message) {
    // Use the subject as the key for fake responses
    final subject = message.decodeSubject() ?? '';
    return _responses[subject];
  }
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

class _FakeSecureStorageService extends SecureStorageService {
  ({String email, String appPassword})? credentials;

  _FakeSecureStorageService() : super();

  @override
  Future<({String email, String appPassword})?> getEmailCredentials() async {
    return credentials;
  }

  @override
  Future<bool> hasEmailCredentials() async {
    return credentials != null;
  }
}

void main() {
  test('importing 4 unique emails inserts 4 transactions', () async {
    var imapService = _FakeImapService();

    // Create fake MimeMessage objects with proper headers
    final email1 = _createTestMessage(subject: 'email-1', date: DateTime.now());
    final email2 = _createTestMessage(subject: 'email-2', date: DateTime.now());
    final email3 = _createTestMessage(subject: 'email-3', date: DateTime.now());
    final email4 = _createTestMessage(subject: 'email-4', date: DateTime.now());

    imapService.emails = [email1, email2, email3, email4];

    final emailParser = _FakeNayaPayEmailService({
      'email-1': _makeTransaction(
        transactionId: 'pay-1',
        beneficiary: 'Merchant A',
      ),
      'email-2': _makeTransaction(
        transactionId: 'pay-2',
        beneficiary: 'Merchant B',
      ),
      'email-3': _makeTransaction(
        transactionId: 'pay-3',
        beneficiary: 'Merchant C',
      ),
      'email-4': _makeTransaction(
        transactionId: 'pay-4',
        beneficiary: 'Merchant D',
      ),
    });

    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final count = await repository.importEmails();

    expect(count, 4);
    expect(transactions.inserted.length, 4);
    expect(imapService.connected, true);
    expect(imapService.disconnected, true);
  });

  test('duplicate transactionId is skipped', () async {
    var imapService = _FakeImapService();

    final email1 = _createTestMessage(subject: 'dup-1', date: DateTime.now());
    final email2 = _createTestMessage(subject: 'dup-2', date: DateTime.now());

    imapService.emails = [email1, email2];

    final emailParser = _FakeNayaPayEmailService({
      'dup-1': _makeTransaction(
        transactionId: 'duplicate-id',
        beneficiary: 'Shop 1',
      ),
      'dup-2': _makeTransaction(
        transactionId: 'duplicate-id',
        beneficiary: 'Shop 1',
      ),
    });

    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final count = await repository.importEmails();

    expect(count, 1);
    expect(transactions.inserted.length, 1);
    expect(transactions.inserted.first.transactionId, 'duplicate-id');
  });

  test('auto-categorisation applies matching categoryId', () async {
    var imapService = _FakeImapService();

    final email = _createTestMessage(
      subject: 'rule-match',
      date: DateTime.now(),
    );

    imapService.emails = [email];

    final emailParser = _FakeNayaPayEmailService({
      'rule-match': _makeTransaction(
        transactionId: 'rule-1',
        beneficiary: 'Starbucks Coffee Lahore',
      ),
    });

    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([
      const RuleModel(id: 1, keyword: 'coffee', categoryId: 99),
    ]);
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final count = await repository.importEmails();

    expect(count, 1);
    expect(transactions.inserted.length, 1);
    expect(transactions.inserted.first.categoryId, 99);
  });

  test('credentials missing throws exception', () async {
    var imapService = _FakeImapService();
    final emailParser = _FakeNayaPayEmailService({});
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);
    final storage = _FakeSecureStorageService()
      ..credentials = null; // No credentials

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    expect(() => repository.importEmails(), throwsException);
  });

  test('empty email list returns 0', () async {
    var imapService = _FakeImapService()..emails = [];
    final emailParser = _FakeNayaPayEmailService({});
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final count = await repository.importEmails();

    expect(count, 0);
    expect(transactions.inserted, isEmpty);
  });

  test('testConnection returns true when credentials valid', () async {
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    var imapService = _FakeImapService()..connectionTestResult = true;

    final emailParser = _FakeNayaPayEmailService({});
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final result = await repository.testConnection();

    expect(result, true);
  });

  test('testConnection returns false when credentials missing', () async {
    final storage = _FakeSecureStorageService()..credentials = null;

    var imapService = _FakeImapService();
    final emailParser = _FakeNayaPayEmailService({});
    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    final result = await repository.testConnection();

    expect(result, false);
  });

  test('disconnect is always called even on exception', () async {
    var imapService = _FakeImapService();

    final email = _createTestMessage(subject: 'email-1', date: DateTime.now());
    imapService.emails = [email];

    final emailParser = _FakeNayaPayEmailService({
      'email-1': null, // Simulate parsing failure for all emails
    });

    final transactions = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([]);
    final storage = _FakeSecureStorageService()
      ..credentials = (email: 'user@gmail.com', appPassword: 'app-pwd');

    final repository = EmailImportRepositoryImpl(
      nayaPayEmailService: emailParser,
      transactionRepository: transactions,
      ruleRepository: rules,
      autoCategorisationService: AutoCategorisationService(),
      secureStorageService: storage,
      imapServiceFactory: (_, __) => imapService,
    );

    await repository.importEmails();

    expect(imapService.disconnected, true);
  });
}
