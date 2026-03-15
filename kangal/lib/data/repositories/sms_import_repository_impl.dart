import 'dart:async';
import 'dart:developer' as developer;

import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/hbl_sms_service.dart';
import 'package:kangal/data/services/sms_inbox_service.dart';
import 'package:kangal/data/services/auto_categorisation_service.dart';
import 'package:telephony/telephony.dart';

class SmsImportRepositoryImpl implements SmsImportRepository {
  final SmsInboxService _smsInboxService;
  final HblSmsService _hblSmsService;
  final TransactionRepository _transactionRepository;
  final RuleRepository _ruleRepository;
  final AutoCategorisationService _autoCategorisationService;

  SmsImportRepositoryImpl({
    required SmsInboxService smsInboxService,
    required HblSmsService hblSmsService,
    required TransactionRepository transactionRepository,
    required RuleRepository ruleRepository,
    required AutoCategorisationService autoCategorisationService,
  }) : _smsInboxService = smsInboxService,
       _hblSmsService = hblSmsService,
       _transactionRepository = transactionRepository,
       _ruleRepository = ruleRepository,
       _autoCategorisationService = autoCategorisationService;

  @override
  Future<int> importHistoricalSms({int? daysBack}) async {
    final messages = await _smsInboxService.getHblMessages(daysBack: daysBack);
    final rules = await _ruleRepository.getAllRules();

    var parsedCount = 0;
    var duplicateCount = 0;
    var importedCount = 0;
    for (final message in messages) {
      final result = await _importSmsMessage(message, rules);
      if (result == _SmsImportResult.imported) {
        importedCount += 1;
      } else if (result == _SmsImportResult.parsedButDuplicate) {
        parsedCount += 1;
        duplicateCount += 1;
      } else if (result == _SmsImportResult.parsedButNotInserted) {
        parsedCount += 1;
      }
    }

    developer.log(
      'SMS import summary: fetched=${messages.length}, parsed=${parsedCount + importedCount}, duplicates=$duplicateCount, inserted=$importedCount, daysBack=${daysBack ?? 'all'}',
      name: 'SmsImportRepository',
    );

    return importedCount;
  }

  @override
  void startRealtimeListener() {
    _smsInboxService.listenForNewSms((message) {
      unawaited(_importSmsMessage(message, null));
    });
  }

  Future<_SmsImportResult> _importSmsMessage(
    SmsMessage message,
    List<RuleModel>? preloadedRules,
  ) async {
    final body = message.body;
    if (body == null || body.trim().isEmpty) {
      return _SmsImportResult.notParsed;
    }

    final parsedTransaction = _hblSmsService.parseHblSms(body);
    if (parsedTransaction == null) {
      return _SmsImportResult.notParsed;
    }

    final transactionId = parsedTransaction.transactionId;
    if (transactionId != null && transactionId.isNotEmpty) {
      final existing = await _transactionRepository
          .getTransactionByTransactionId(transactionId);
      if (existing != null) {
        return _SmsImportResult.parsedButDuplicate;
      }
    }

    final rules = preloadedRules ?? await _ruleRepository.getAllRules();
    final categoryId =
        _autoCategorisationService.applyCategoryRules(
          parsedTransaction,
          rules,
        ) ??
        parsedTransaction.categoryId;
    final transactionToInsert = parsedTransaction.copyWith(
      categoryId: categoryId,
    );

    await _transactionRepository.insertTransaction(transactionToInsert);
    return _SmsImportResult.imported;
  }
}

enum _SmsImportResult { notParsed, parsedButDuplicate, parsedButNotInserted, imported }
