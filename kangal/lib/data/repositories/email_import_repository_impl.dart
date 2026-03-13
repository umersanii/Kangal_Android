import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/imap_service.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:enough_mail/enough_mail.dart';

abstract class ImapServiceInterface {
  Future<void> connect();
  Future<void> disconnect();
  Future<List<MimeMessage>> fetchNayaPayEmails({int daysBack = 90});
  Future<bool> testConnection();
}

typedef ImapServiceFactory = ImapServiceInterface Function(
  String email,
  String appPassword,
);

ImapServiceInterface _defaultImapServiceFactory(
  String email,
  String appPassword,
) {
  return ImapServiceAdapter(
    ImapService(email: email, appPassword: appPassword),
  );
}

class ImapServiceAdapter implements ImapServiceInterface {
  final ImapService _service;

  ImapServiceAdapter(this._service);

  @override
  Future<void> connect() => _service.connect();

  @override
  Future<void> disconnect() => _service.disconnect();

  @override
  Future<List<MimeMessage>> fetchNayaPayEmails({int daysBack = 90}) =>
      _service.fetchNayaPayEmails(daysBack: daysBack);

  @override
  Future<bool> testConnection() => _service.testConnection();
}

class EmailImportRepositoryImpl implements EmailImportRepository {
  final NayaPayEmailService _nayaPayEmailService;
  final TransactionRepository _transactionRepository;
  final RuleRepository _ruleRepository;
  final SecureStorageService _secureStorageService;
  final AutoCategorisationService _autoCategorisationService;
  final ImapServiceFactory _imapServiceFactory;

  EmailImportRepositoryImpl({
    required NayaPayEmailService nayaPayEmailService,
    required TransactionRepository transactionRepository,
    required RuleRepository ruleRepository,
    required SecureStorageService secureStorageService,
    required AutoCategorisationService autoCategorisationService,
    ImapServiceFactory? imapServiceFactory,
  })  : _nayaPayEmailService = nayaPayEmailService,
        _transactionRepository = transactionRepository,
        _ruleRepository = ruleRepository,
        _secureStorageService = secureStorageService,
        _autoCategorisationService = autoCategorisationService,
        _imapServiceFactory = imapServiceFactory ?? _defaultImapServiceFactory;

  @override
  Future<int> importEmails() async {
    final credentials = await _secureStorageService.getEmailCredentials();
    if (credentials == null) {
      throw Exception('Email credentials not configured');
    }

    final imapService = _imapServiceFactory(
      credentials.email,
      credentials.appPassword,
    );

    try {
      await imapService.connect();
      final emails = await imapService.fetchNayaPayEmails(daysBack: 90);
      final rules = await _ruleRepository.getAllRules();

      var importedCount = 0;

      for (final email in emails) {
        final parsedTransaction = _nayaPayEmailService.parseEmail(email);
        if (parsedTransaction == null) {
          continue;
        }

        final transactionId = parsedTransaction.transactionId;
        if (transactionId != null && transactionId.isNotEmpty) {
          final existing = await _transactionRepository
              .getTransactionByTransactionId(transactionId);
          if (existing != null) {
            continue;
          }
        }

        final categoryId = _autoCategorisationService.applyCategoryRules(parsedTransaction, rules) ?? parsedTransaction.categoryId;
        final transactionToInsert = parsedTransaction.copyWith(
          categoryId: categoryId,
        );

        await _transactionRepository.insertTransaction(transactionToInsert);
        importedCount++;
      }

      return importedCount;
    } finally {
      await imapService.disconnect();
    }
  }

  @override
  Future<bool> testConnection() async {
    final credentials = await _secureStorageService.getEmailCredentials();
    if (credentials == null) {
      return false;
    }

    final imapService = _imapServiceFactory(
      credentials.email,
      credentials.appPassword,
    );

    return imapService.testConnection();
  }
}
