import 'dart:async';

import 'package:kangal/data/models/rule_model.dart';
import 'package:kangal/data/models/transaction_model.dart';
import 'package:kangal/data/repositories/rule_repository.dart';
import 'package:kangal/data/repositories/sms_import_repository.dart';
import 'package:kangal/data/repositories/transaction_repository.dart';
import 'package:kangal/data/services/hbl_sms_service.dart';
import 'package:kangal/data/services/sms_inbox_service.dart';
import 'package:telephony/telephony.dart';

class SmsImportRepositoryImpl implements SmsImportRepository {
  final SmsInboxService _smsInboxService;
  final HblSmsService _hblSmsService;
  final TransactionRepository _transactionRepository;
  final RuleRepository _ruleRepository;

  SmsImportRepositoryImpl({
    required SmsInboxService smsInboxService,
    required HblSmsService hblSmsService,
    required TransactionRepository transactionRepository,
    required RuleRepository ruleRepository,
  }) : _smsInboxService = smsInboxService,
       _hblSmsService = hblSmsService,
       _transactionRepository = transactionRepository,
       _ruleRepository = ruleRepository;

  @override
  Future<int> importHistoricalSms() async {
    final messages = await _smsInboxService.getHblMessages();
    final rules = await _ruleRepository.getAllRules();

    var importedCount = 0;
    for (final message in messages) {
      if (await _importSmsMessage(message, rules)) {
        importedCount++;
      }
    }

    return importedCount;
  }

  @override
  void startRealtimeListener() {
    _smsInboxService.listenForNewSms((message) {
      unawaited(_importSmsMessage(message, null));
    });
  }

  Future<bool> _importSmsMessage(
    SmsMessage message,
    List<RuleModel>? preloadedRules,
  ) async {
    final body = message.body;
    if (body == null || body.trim().isEmpty) {
      return false;
    }

    final parsedTransaction = _hblSmsService.parseHblSms(body);
    if (parsedTransaction == null) {
      return false;
    }

    final transactionId = parsedTransaction.transactionId;
    if (transactionId != null && transactionId.isNotEmpty) {
      final existing = await _transactionRepository
          .getTransactionByTransactionId(transactionId);
      if (existing != null) {
        return false;
      }
    }

    final rules = preloadedRules ?? await _ruleRepository.getAllRules();
    final categoryId = _resolveCategoryId(parsedTransaction, rules);
    final transactionToInsert = parsedTransaction.copyWith(
      categoryId: categoryId,
    );

    await _transactionRepository.insertTransaction(transactionToInsert);
    return true;
  }

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
