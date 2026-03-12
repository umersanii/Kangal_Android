import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/email_import_repository.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/imap_service.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
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
  final ImapServiceFactory _imapServiceFactory;

  EmailImportRepositoryImpl({
    required NayaPayEmailService nayaPayEmailService,
    required TransactionRepository transactionRepository,
    required RuleRepository ruleRepository,
    required SecureStorageService secureStorageService,
    ImapServiceFactory? imapServiceFactory,
  })  : _nayaPayEmailService = nayaPayEmailService,
        _transactionRepository = transactionRepository,
        _ruleRepository = ruleRepository,
        _secureStorageService = secureStorageService,
        _imapServiceFactory = imapServiceFactory ?? _defaultImapServiceFactory;

  @override
  Future<int> importEmails() async {
    // Read credentials from secure storage
    final credentials = await _secureStorageService.getEmailCredentials();
    if (credentials == null) {
      throw Exception('Email credentials not configured');
    }

    // Create IMAP service with stored credentials
    final imapService = _imapServiceFactory(
      credentials.email,
      credentials.appPassword,
    );

    try {
      // Connect to IMAP
      await imapService.connect();

      // Fetch NayaPay emails from last 90 days
      final emails = await imapService.fetchNayaPayEmails(daysBack: 90);

      // Preload all rules for efficient categorisation
      final rules = await _ruleRepository.getAllRules();

      var importedCount = 0;

      for (final email in emails) {
        // Parse the email
        final parsedTransaction = _nayaPayEmailService.parseEmail(email);
        if (parsedTransaction == null) {
          continue;
        }

        // Check for deduplication by transactionId
        final transactionId = parsedTransaction.transactionId;
        if (transactionId != null && transactionId.isNotEmpty) {
          final existing = await _transactionRepository
              .getTransactionByTransactionId(transactionId);
          if (existing != null) {
            // Transaction already imported, skip
            continue;
          }
        }

        // Apply auto-categorisation rules
        final categoryId = _resolveCategoryId(parsedTransaction, rules);
        final transactionToInsert = parsedTransaction.copyWith(
          categoryId: categoryId,
        );

        // Insert the transaction
        await _transactionRepository.insertTransaction(transactionToInsert);
        importedCount++;
      }

      return importedCount;
    } finally {
      // Always disconnect
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

  /// Resolves the category ID for a transaction by checking if any rules
  /// match the transaction's beneficiary. Returns the matched category ID
  /// or the transaction's current categoryId if no rule matches.
  int? _resolveCategoryId(TransactionModel transaction, List<RuleModel> rules) {
    final beneficiary = transaction.beneficiary?.trim();
    if (beneficiary == null || beneficiary.isEmpty) {
      return transaction.categoryId;
    }

    final target = beneficiary.toLowerCase();
    for (final rule in rules) {
      final keyword = rule.keyword.trim().toLowerCase();
      if (keyword.isNotEmpty && target.contains(keyword)) {
        return rule.categoryId;
      }
    }

    return transaction.categoryId;
  }
}
