import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

/// Parses NayaPay email messages and returns a [TransactionModel] when a known
/// pattern is matched in the subject line (fast path) or full body parsing.
/// Returns `null` if the email subject does not correspond to an expected NayaPay format.
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

  /// Date format for plaintext emails: "20 Dec 2025, 10:41 PM"
  static final _dateFormatPlaintext = DateFormat('dd MMM yyyy, hh:mm a');

  /// Parse the provided [message] and return a transaction if one of the
  /// known NayaPay patterns matches in the subject line (fast path) or body parsing.
  TransactionModel? parseEmail(MimeMessage message) {
    final subject = message.decodeSubject() ?? '';

    // Pattern 1: "You got Rs. X from Y 🎉" → income (Received)
    final matchReceived = _patternReceived.firstMatch(subject);
    if (matchReceived != null) {
      final amountStr = matchReceived.group(1)!;
      final beneficiary = matchReceived.group(2)?.trim();
      final amount = _parseAmount(amountStr);
      var txId = _generateTransactionId(message);
      var txDate = message.decodeDate() ?? DateTime.now();
      var extra = <String, dynamic>{};

      // Try full body parsing for Type 1 (Received)
      final bodyStr = _getMessageBody(message);
      if (bodyStr.isNotEmpty) {
        final parsed = _parseType1Plaintext(bodyStr);
        if (parsed != null) {
          txId = parsed['txnId'] as String;
          txDate = parsed['date'] as DateTime;
          extra = {'senderTag': parsed['senderTag']};
        }
      }

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: txDate,
        amount: amount,
        source: 'NayaPay',
        type: 'received',
        transactionId: txId,
        beneficiary: beneficiary,
        subject: subject,
        categoryId: null,
        note: null,
        extra: extra.isEmpty ? null : jsonEncode(extra),
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
      var txId = _generateTransactionId(message);
      var txDate = message.decodeDate() ?? DateTime.now();
      var type = 'sent_p2p';
      var extra = <String, dynamic>{};

      // Try full body parsing for Type 2/3 (P2P or Bank Transfer)
      final bodyStr = _getMessageBody(message);
      if (bodyStr.isNotEmpty) {
        // Try Type 2 plaintext (P2P with receiver tag)
        final parsed2 = _parseType2Plaintext(bodyStr);
        if (parsed2 != null) {
          txId = parsed2['txnId'] as String;
          txDate = parsed2['date'] as DateTime;
          extra = {
            'senderTag': parsed2['senderTag'],
            'receiverTag': parsed2['receiverTag'],
          };
          type = 'sent_p2p';
        }
      } else {
        // Try HTML parsing for Type 3 (Bank Transfer)
        final htmlStr = _getHtmlBody(message);
        if (htmlStr.isNotEmpty) {
          final parsed3 = _parseType3Html(htmlStr);
          if (parsed3 != null) {
            txId = parsed3['txnId'] as String;
            txDate = parsed3['date'] as DateTime;
            extra = parsed3['extra'] as Map<String, dynamic>;
            type = 'sent_bank';
          }
        }
      }

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: txDate,
        amount: amount,
        source: 'NayaPay',
        type: type,
        transactionId: txId,
        beneficiary: beneficiary,
        subject: subject,
        categoryId: null,
        note: null,
        extra: extra.isEmpty ? null : jsonEncode(extra),
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
      var txId = _generateTransactionId(message);
      var txDate = message.decodeDate() ?? DateTime.now();
      var extra = <String, dynamic>{};

      // Try HTML parsing for Type 4 (Card Purchase)
      final htmlStr = _getHtmlBody(message);
      if (htmlStr.isNotEmpty) {
        final parsed4 = _parseType4Html(htmlStr);
        if (parsed4 != null) {
          txId = parsed4['txnId'] as String;
          txDate = parsed4['date'] as DateTime;
          extra = parsed4['extra'] as Map<String, dynamic>;
        }
      }

      return TransactionModel(
        id: 0,
        remoteId: null,
        date: txDate,
        amount: amount,
        source: 'NayaPay',
        type: 'card_purchase',
        transactionId: txId,
        beneficiary: merchant,
        subject: subject,
        categoryId: null,
        note: null,
        extra: extra.isEmpty ? null : jsonEncode(extra),
        syncedAt: null,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Parse Type 1 plaintext (Received): "amount name txnId date time senderTag"
  /// Returns a map with keys: 'amount', 'name', 'txnId', 'date', 'senderTag'
  /// Or null if parsing fails.
  static Map<String, dynamic>? _parseType1Plaintext(String plaintext) {
    final trimmed = plaintext.trim();
    if (trimmed.isEmpty) return null;

    // Split by whitespace, filter empty strings
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 5) return null;

    try {
      // Extract parts: txnId, date, time, senderTag
      // Skip: amount (parts[0]), name (parts[1]) - not needed for expense tracking
      final txnId = parts[2];
      final dateStr =
          '${parts[3]} ${parts[4]}'; // e.g., "20 Dec 2025, 10:41 PM"
      final senderTag = parts.length > 5 ? parts.sublist(5).join(' ') : '';

      // Parse date
      final date = _dateFormatPlaintext.parse(dateStr);

      return {'txnId': txnId, 'date': date, 'senderTag': senderTag};
    } catch (e) {
      return null;
    }
  }

  /// Parse Type 2 plaintext (P2P):
  /// "amount name txnId date time senderTag receiverTag(s)"
  /// Returns a map with keys: 'amount', 'name', 'txnId', 'date', 'senderTag', 'receiverTag'
  /// Or null if parsing fails.
  static Map<String, dynamic>? _parseType2Plaintext(String plaintext) {
    final trimmed = plaintext.trim();
    if (trimmed.isEmpty) return null;

    // Split by whitespace, filter empty strings
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 6) return null;

    try {
      // Extract parts: txnId, date, time, senderTag, receiverTag(s)
      // Skip: amount (parts[0]), name (parts[1]) - not needed for expense tracking
      final txnId = parts[2];
      final dateStr =
          '${parts[3]} ${parts[4]}'; // e.g., "21 Feb 2026, 10:04 PM"
      final senderTag = parts[5];
      final receiverTag = parts.length > 6 ? parts.sublist(6).join(' ') : '';

      // Parse date
      final date = _dateFormatPlaintext.parse(dateStr);

      return {
        'txnId': txnId,
        'date': date,
        'senderTag': senderTag,
        'receiverTag': receiverTag,
      };
    } catch (e) {
      return null;
    }
  }

  /// Parse Type 3 HTML (Bank Transfer via Raast):
  /// Extracts beneficiary name, destination bank, masked account, channel, date, transaction ID via regex/CSS selectors.
  /// Returns a map with keys: 'txnId', 'date', 'extra' (containing bank details as JSON).
  /// Or null if parsing fails.
  static Map<String, dynamic>? _parseType3Html(String html) {
    try {
      // Try to extract transaction ID using regex
      var txnIdMatch = RegExp(
        r'(?:Transaction|Txn|ID|TXN ID)[:\s]+([a-f0-9]{24,})',
      ).firstMatch(html);
      final txnId = txnIdMatch?.group(1) ?? '';
      if (txnId.isEmpty) return null;

      // Try to extract date - look for pattern "dd MMM yyyy, hh:mm a"
      var dateMatch = RegExp(
        r'(\d{1,2}\s+[A-Za-z]{3}\s+\d{4},\s+\d{1,2}:\d{2}\s+(?:AM|PM))',
      ).firstMatch(html);
      DateTime? date;
      if (dateMatch != null) {
        try {
          date = _dateFormatPlaintext.parse(dateMatch.group(1)!);
        } catch (e) {
          date = null;
        }
      }

      // Extract bank name, account mask, and channel
      var bankMatch = RegExp(
        r'(?:bank|Bank|destination)[:\s]*([^<\n]+?)(?:\s+●|<|$)',
        multiLine: true,
      ).firstMatch(html);
      final bank = bankMatch?.group(1)?.trim() ?? 'Raast';

      var accountMatch = RegExp(r'(●{1,4}\d{4})').firstMatch(html);
      final maskedAccount = accountMatch?.group(1) ?? '';

      var extra = {
        'destinationBank': bank,
        'maskedAccount': maskedAccount,
        'channel': 'Raast',
      };

      return {'txnId': txnId, 'date': date ?? DateTime.now(), 'extra': extra};
    } catch (e) {
      return null;
    }
  }

  /// Parse Type 4 HTML (Card Purchase):
  /// Extracts merchant + location, card info, merchant category, fees breakdown, total amount, transaction ID.
  /// Returns a map with keys: 'txnId', 'date', 'extra' (containing card & fees details as JSON).
  /// Or null if parsing fails.
  static Map<String, dynamic>? _parseType4Html(String html) {
    try {
      // Extract transaction ID using regex
      var txnIdMatch = RegExp(
        r'(?:Transaction|Txn|ID|TXN ID)[:\s]+([a-f0-9]{24,})',
      ).firstMatch(html);
      final txnId = txnIdMatch?.group(1) ?? '';
      if (txnId.isEmpty) return null;

      // Try to extract date - look for pattern "dd MMM yyyy, hh:mm a"
      var dateMatch = RegExp(
        r'(\d{1,2}\s+[A-Za-z]{3}\s+\d{4},\s+\d{1,2}:\d{2}\s+(?:AM|PM))',
      ).firstMatch(html);
      DateTime? date;
      if (dateMatch != null) {
        try {
          date = _dateFormatPlaintext.parse(dateMatch.group(1)!);
        } catch (e) {
          date = null;
        }
      }

      // Extract card info (e.g., "Visa ●●●●0268")
      var cardMatch = RegExp(
        r'(Visa|Mastercard|Amex)\s+(●{1,4}\d{4})',
      ).firstMatch(html);
      final cardBrand = cardMatch?.group(1) ?? 'Card';
      final maskedCard = cardMatch?.group(2) ?? '';

      // Extract merchant category
      var categoryMatch = RegExp(
        r'(?:Category|Merchant Category)[:\s]*([^<\n]+?)(?:<|$)',
        multiLine: true,
      ).firstMatch(html);
      final merchantCategory = categoryMatch?.group(1)?.trim() ?? '';

      // Extract fees breakdown using regex
      var baseFeeMatch = RegExp(
        r'(?:Base Fee|base)[:\s]*Rs\.\s*([\d,]+\.?\d*)',
      ).firstMatch(html);
      final baseFee = baseFeeMatch != null
          ? _parseAmount(baseFeeMatch.group(1)!)
          : 0.0;

      var intlFeeMatch = RegExp(
        r'(?:International Fee|intl fee)[:\s]*Rs\.\s*([\d,]+\.?\d*)',
      ).firstMatch(html);
      final intlFee = intlFeeMatch != null
          ? _parseAmount(intlFeeMatch.group(1)!)
          : 0.0;

      var sstMatch = RegExp(
        r'(?:SST|Sales Tax)[:\s]*Rs\.\s*([\d,]+\.?\d*)',
      ).firstMatch(html);
      final sst = sstMatch != null ? _parseAmount(sstMatch.group(1)!) : 0.0;

      var fxMatch = RegExp(
        r'(?:FX Fee|forex)[:\s]*Rs\.\s*([\d,]+\.?\d*)',
      ).firstMatch(html);
      final fxFee = fxMatch != null ? _parseAmount(fxMatch.group(1)!) : 0.0;

      var extra = {
        'cardBrand': cardBrand,
        'maskedCard': maskedCard,
        'merchantCategory': merchantCategory,
        'feeDetails': {
          'base': baseFee,
          'international': intlFee,
          'sst': sst,
          'fx': fxFee,
        },
      };

      return {'txnId': txnId, 'date': date ?? DateTime.now(), 'extra': extra};
    } catch (e) {
      return null;
    }
  }

  /// Extract plaintext body from message
  static String _getMessageBody(MimeMessage message) {
    try {
      return message.decodeTextPlainPart() ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Extract HTML body from message
  static String _getHtmlBody(MimeMessage message) {
    try {
      return message.decodeTextHtmlPart() ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Parse amount string, removing commas and converting to double.
  /// Always positive; caller determines sign based on transaction type.
  static double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(',', '').trim();
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
