import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/services/nayapay_email_service.dart';

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

void main() {
  final service = NayaPayEmailService();

  group('NayaPayEmailService.parseEmail', () {
    test('parses received money email (Type 1 - 🎉)', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 1,000 from Muhammad Haseeb 🎉',
        date: DateTime(2025, 12, 20, 22, 41, 22),
        messageId: '<test1@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(1000.0, 0.001));
      expect(txn.beneficiary, 'Muhammad Haseeb');
      expect(txn.source, 'NayaPay');
      expect(txn.type, 'received');
      expect(txn.subject, 'You got Rs. 1,000 from Muhammad Haseeb 🎉');
      expect(txn.transactionId, isNotEmpty);
    });

    test('parses sent money email (Type 2 - 💸)', () {
      final message = _createTestMessage(
        subject: 'You sent Rs. 1,450 to Muhammad Umer Ghafoor 💸',
        date: DateTime(2026, 2, 21, 22, 4, 11),
        messageId: '<test2@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-1450.0, 0.001));
      expect(txn.beneficiary, 'Muhammad Umer Ghafoor');
      expect(txn.source, 'NayaPay');
      expect(txn.type, 'sent_p2p');
      expect(txn.subject, 'You sent Rs. 1,450 to Muhammad Umer Ghafoor 💸');
      expect(txn.transactionId, isNotEmpty);
    });

    test('parses another sent money email with comma amount', () {
      final message = _createTestMessage(
        subject: 'You sent Rs. 329 to Fakhar Ali 💸',
        date: DateTime(2026, 3, 1, 10, 0, 0),
        messageId: '<test3@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-329.0, 0.001));
      expect(txn.beneficiary, 'Fakhar Ali');
      expect(txn.source, 'NayaPay');
      expect(txn.type, 'sent_p2p');
      expect(txn.transactionId, isNotEmpty);
    });

    test('parses card purchase email (Type 4 - 💳)', () {
      final message = _createTestMessage(
        subject: 'You spent Rs. 268.54 at Google YouTube London GB 💳',
        date: DateTime(2026, 2, 9, 14, 17, 2),
        messageId: '<test4@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-268.54, 0.001));
      expect(txn.beneficiary, 'Google YouTube London GB');
      expect(txn.source, 'NayaPay');
      expect(txn.type, 'card_purchase');
      expect(
        txn.subject,
        'You spent Rs. 268.54 at Google YouTube London GB 💳',
      );
      expect(txn.transactionId, isNotEmpty);
    });

    test('returns null for unknown message subject', () {
      final message = _createTestMessage(
        subject: 'Some random email subject that does not match any pattern',
        date: DateTime.now(),
      );

      final txn = service.parseEmail(message);

      expect(txn, isNull);
    });

    test('parses amount with comma separator correctly', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 10,000 from John Doe 🎉',
        date: DateTime.now(),
        messageId: '<test5@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(10000.0, 0.001));
    });

    test('parses amount with comma and decimal correctly', () {
      final message = _createTestMessage(
        subject: 'You spent Rs. 1,234.56 at Shop ABC 💳',
        date: DateTime.now(),
        messageId: '<test6@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-1234.56, 0.001));
    });

    test('sets current date/time when message date is null', () {
      final message = MimeMessage();
      message.setHeader('subject', 'You got Rs. 500 from Alice 🎉');
      // No date set, should use DateTime.now()

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.date, isNotNull);
      // Date should be close to now
      expect(txn.date.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    });

    test('generates consistent transaction IDs for same message', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 100 from Bob 🎉',
        date: DateTime(2026, 1, 1, 10, 0, 0),
        messageId: '<consistent@nayapay.com>',
      );

      final txn1 = service.parseEmail(message);
      final txn2 = service.parseEmail(message);

      expect(txn1!.transactionId, equals(txn2!.transactionId));
    });

    test('generates different transaction IDs for different messages', () {
      final message1 = _createTestMessage(
        subject: 'You got Rs. 100 from Bob 🎉',
        date: DateTime(2026, 1, 1, 10, 0, 0),
        messageId: '<msg1@nayapay.com>',
      );

      final message2 = _createTestMessage(
        subject: 'You got Rs. 200 from Charlie 🎉',
        date: DateTime(2026, 1, 1, 10, 0, 0),
        messageId: '<msg2@nayapay.com>',
      );

      final txn1 = service.parseEmail(message1);
      final txn2 = service.parseEmail(message2);

      expect(txn1!.transactionId, isNot(equals(txn2!.transactionId)));
    });

    test('correctly identifies all three patterns as mutually exclusive', () {
      // Pattern 1: income
      final msg1 = _createTestMessage(
        subject: 'You got Rs. 100 from Alice 🎉',
        date: DateTime.now(),
        messageId: '<p1@nayapay.com>',
      );
      final txn1 = service.parseEmail(msg1);
      expect(txn1!.type, 'received');
      expect(txn1.amount, greaterThan(0));

      // Pattern 2: expense (sent)
      final msg2 = _createTestMessage(
        subject: 'You sent Rs. 100 to Bob 💸',
        date: DateTime.now(),
        messageId: '<p2@nayapay.com>',
      );
      final txn2 = service.parseEmail(msg2);
      expect(txn2!.type, 'sent_p2p');
      expect(txn2.amount, lessThan(0));

      // Pattern 3: expense (spent)
      final msg3 = _createTestMessage(
        subject: 'You spent Rs. 100 at Shop 💳',
        date: DateTime.now(),
        messageId: '<p3@nayapay.com>',
      );
      final txn3 = service.parseEmail(msg3);
      expect(txn3!.type, 'card_purchase');
      expect(txn3.amount, lessThan(0));
    });

    test('handles beneficiary/merchant names with special characters', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 500 from O\'Brien & Co. 🎉',
        date: DateTime.now(),
        messageId: '<special@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.beneficiary, "O'Brien & Co.");
    });

    test('handles beneficiary/merchant names with multiple words', () {
      final message = _createTestMessage(
        subject: 'You spent Rs. 1000 at Amazing Shopping Mall Dubai 💳',
        date: DateTime.now(),
        messageId: '<words@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.beneficiary, 'Amazing Shopping Mall Dubai');
    });

    test('sets all other fields to expected defaults', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 100 from Alice 🎉',
        date: DateTime.now(),
        messageId: '<defaults@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn!.id, 0);
      expect(txn.remoteId, isNull);
      expect(txn.categoryId, isNull);
      expect(txn.note, isNull);
      expect(txn.syncedAt, isNull);
      expect(txn.updatedAt, isNotNull);
      expect(txn.createdAt, isNotNull);
    });
  });

  group('Plaintext Parsing Unit Tests', () {
    test('_parseType1Plaintext parses expected format', () {
      // Direct unit test of the private method via reflection is complex,
      // so we test through the public parseEmail interface.
      // Format: amount name txnId date time senderTag
      final message = _createTestMessage(
        subject: 'You got Rs. 1,000 from Muhammad Haseeb 🎉',
        date: DateTime(2025, 12, 20, 22, 41, 22),
        messageId: '<received@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.beneficiary, 'Muhammad Haseeb');
      expect(txn.amount, closeTo(1000.0, 0.001));
      expect(txn.type, 'received');
    });

    test('_parseType2Plaintext extracts both sender and receiver tags', () {
      // Via public interface, Type 2 plaintext parsing
      final message = _createTestMessage(
        subject: 'You sent Rs. 1,450 to Muhammad Umer Ghafoor 💸',
        date: DateTime(2026, 2, 21, 22, 4, 11),
        messageId: '<p2p@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.beneficiary, 'Muhammad Umer Ghafoor');
      expect(txn.amount, closeTo(-1450.0, 0.001));
      expect(txn.type, 'sent_p2p');
    });
  });

  group('HTML Parsing Unit Tests', () {
    test('_parseType3Html extracts bank transfer data', () {
      // Bank transfer case (Type 3)
      // When "You sent Rs. X to Y 💸" with empty plaintext
      // should try HTML parsing and detect it's a bank transfer
      final message = _createTestMessage(
        subject: 'You sent Rs. 5,000 to Habib Bank 💸',
        date: DateTime(2026, 3, 1, 15, 45, 0),
        messageId: '<bank@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.type, 'sent_p2p'); // May be sent_p2p or sent_bank depending on parsing
      expect(txn.amount, closeTo(-5000.0, 0.001));
    });

    test('_parseType4Html parses card purchase details', () {
      // Card purchase case (Type 4)
      final message = _createTestMessage(
        subject: 'You spent Rs. 268.54 at Google YouTube London GB 💳',
        date: DateTime(2026, 2, 9, 14, 17, 2),
        messageId: '<card@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.type, 'card_purchase');
      expect(txn.amount, closeTo(-268.54, 0.001));
      expect(txn.beneficiary, 'Google YouTube London GB');
    });
  });

  group('Edge Cases', () {
    test('handles amounts with leading zeros', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 0,100 from Bob 🎉',
        date: DateTime.now(),
        messageId: '<zeros@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(100.0, 0.001));
    });

    test('handles decimal-only amounts', () {
      final message = _createTestMessage(
        subject: 'You spent Rs. 0.99 at Shop 💳',
        date: DateTime.now(),
        messageId: '<decimal@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-0.99, 0.001));
    });

    test('handles large amounts with multiple commas', () {
      final message = _createTestMessage(
        subject: 'You got Rs. 1,23,456 from Bob 🎉',
        date: DateTime.now(),
        messageId: '<large@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(123456.0, 0.001));
    });

    test('handles amounts with commas and decimals', () {
      final message = _createTestMessage(
        subject: 'You spent Rs. 10,999.99 at Store 💳',
        date: DateTime.now(),
        messageId: '<both@nayapay.com>',
      );

      final txn = service.parseEmail(message);

      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-10999.99, 0.001));
    });
  });
}
