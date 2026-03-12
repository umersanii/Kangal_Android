import 'package:crypto/crypto.dart';
import 'package:enough_mail/enough_mail.dart';

import '../models/transaction_model.dart';

/// Parses NayaPay email messages and returns a [TransactionModel] when a known
/// pattern is matched in the subject line (fast path). Returns `null` if the
/// email subject does not correspond to an expected NayaPay transaction format.
class NayaPayEmailService {
  /// Pattern for: "You got Rs. X from Y 🎉" (income)
  static final _patternReceived = RegExp(
    r"You got Rs\.\s*([\d,]+(?:\.\d+)?)\s*from\s+(.+?)\s*🎉",
    caseSensitive: false,
  );

  /// Pattern for: "You sent Rs. X to Y 💸" (expense - P2P or bank transfer)
  static final _patternSent = RegExp(
    r"You sent Rs\.\s*([\d,]+(?:\.\d+)?)\s*to\s+(.+?)\s*💸",
    caseSensitive: false,
  );

  /// Pattern for: "You spent Rs. X at Y 💳" (expense - card purchase)
  static final _patternSpent = RegExp(
    r"You spent Rs\.\s*([\d,]+(?:\.\d+)?)\s*at\s+(.+?)\s*💳",
    caseSensitive: false,
  );

  /// Parse the provided [message] and return a transaction if one of the
  /// known NayaPay patterns matches in the subject line (fast path).
  TransactionModel? parseEmail(MimeMessage message) {
    final subject = message.decodeSubject() ?? '';

    // Pattern 1: "You got Rs. X from Y 🎉" → income
    final matchReceived = _patternReceived.firstMatch(subject);
    if (matchReceived != null) {
      final amountStr = matchReceived.group(1)!;
      final beneficiary = matchReceived.group(2)?.trim();
      final amount = _parseAmount(amountStr);
      final txId = _generateTransactionId(message);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: message.decodeDate() ?? DateTime.now(),
        amount: amount,
        source: 'NayaPay',
        type: 'received',
        transactionId: txId,
        beneficiary: beneficiary,
        subject: subject,
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    // Pattern 2: "You sent Rs. X to Y 💸" → expense (P2P or bank transfer)
    final matchSent = _patternSent.firstMatch(subject);
    if (matchSent != null) {
      final amountStr = matchSent.group(1)!;
      final beneficiary = matchSent.group(2)?.trim();
      final amount = -_parseAmount(amountStr);
      final txId = _generateTransactionId(message);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: message.decodeDate() ?? DateTime.now(),
        amount: amount,
        source: 'NayaPay',
        type: 'sent_p2p',
        transactionId: txId,
        beneficiary: beneficiary,
        subject: subject,
        categoryId: null,
        note: null,
        extra: null,
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    // Pattern 3: "You spent Rs. X at Y 💳" → expense (card purchase)
    final matchSpent = _patternSpent.firstMatch(subject);
    if (matchSpent != null) {
      final amountStr = matchSpent.group(1)!;
      final merchant = matchSpent.group(2)?.trim();
      final amount = -_parseAmount(amountStr);
      final txId = _generateTransactionId(message);

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: message.decodeDate() ?? DateTime.now(),
        amount: amount,
        source: 'NayaPay',
        type: 'card_purchase',
        transactionId: txId,
        beneficiary: merchant,
        subject: subject,
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

  /// Parse amount string, removing commas and converting to double.
  /// Always positive; caller determines sign based on transaction type.
  static double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Generate a unique transaction ID using SHA-256 hash of message ID and subject.
  /// Falls back to a hash of subject and date if message ID is unavailable.
  static String _generateTransactionId(MimeMessage message) {
    final messageId = message.getHeaderValue('message-id') ?? '';
    final subject = message.decodeSubject() ?? '';
    final identifier = '$messageId:$subject';
    return sha256.convert(identifier.codeUnits).toString();
  }
}
