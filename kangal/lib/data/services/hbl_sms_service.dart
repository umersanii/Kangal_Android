import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

/// Parses HBL SMS messages and returns a [TransactionModel] when a known
/// pattern is matched. Returns `null` if the SMS does not correspond to an
/// expected HBL transaction format.
class HblSmsService {
  static final _patternA = RegExp(
    r"HBL Debit Card.*?PKR\s*([\d,]+\.?\d*)\s*on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})",
    caseSensitive: false,
    dotAll: true,
  );

  static final _patternB = RegExp(
    r"HBL A/C.*?debited with PKR\s*([\d,]+\.?\d*)\s*on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}).*?for\s+(.+?)\."
    r"",
    caseSensitive: false,
    dotAll: true,
  );

  static final _patternC = RegExp(
    r"PKR\s*([\d,]+\.?\d*)\s*received from\s+(.+?)\s+A/C.*?on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}).*?TXN ID\s+([^\s.]+)",
    caseSensitive: false,
    dotAll: true,
  );

  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  /// Parse the provided [smsBody] and return a transaction if one of the
  /// known HBL patterns matches.
  TransactionModel? parseHblSms(String smsBody) {
    final lower = smsBody; // we use case-insensitive regex above

    final matchA = _patternA.firstMatch(lower);
    if (matchA != null) {
      final amountStr = matchA.group(1)!;
      final dateStr = matchA.group(2)!;
      final amount = -_parseAmount(amountStr);
      final date = _dateFormat.parse(dateStr);
      final txId = _sha256(smsBody);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: date,
        amount: amount,
        source: 'HBL',
        type: 'card_charge',
        transactionId: txId,
        beneficiary: null,
        subject: smsBody,
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    final matchB = _patternB.firstMatch(lower);
    if (matchB != null) {
      final amountStr = matchB.group(1)!;
      final dateStr = matchB.group(2)!;
      final beneficiary = matchB.group(3)?.trim();
      final amount = -_parseAmount(amountStr);
      final date = _dateFormat.parse(dateStr);
      final txId = _sha256(smsBody);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: date,
        amount: amount,
        source: 'HBL',
        type: 'atm_withdrawal',
        transactionId: txId,
        beneficiary: beneficiary,
        subject: smsBody,
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    final matchC = _patternC.firstMatch(lower);
    if (matchC != null) {
      final amountStr = matchC.group(1)!;
      final beneficiary = matchC.group(2)?.trim();
      final dateStr = matchC.group(3)!;
      var txnId = matchC.group(4)!;
      txnId = txnId.replaceFirst(RegExp(r'[.,]$'), '');
      final amount = _parseAmount(amountStr);
      final date = _dateFormat.parse(dateStr);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: date,
        amount: amount,
        source: 'HBL',
        type: 'raast_received',
        transactionId: txnId,
        beneficiary: beneficiary,
        subject: smsBody,
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
