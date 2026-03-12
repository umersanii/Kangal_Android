import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/services/hbl_sms_service.dart';
import 'package:intl/intl.dart';

void main() {
  final service = HblSmsService();
  final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

  group('HblSmsService.parseHblSms', () {
    test('parses debit card charge (pattern A)', () {
      const msg =
          'Your HBL Debit Card has been charged for a Transaction of PKR 1712.19 on 05/03/2026 19:21:32.';
      final txn = service.parseHblSms(msg);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-1712.19, 0.001));
      expect(txn.date, formatter.parse('05/03/2026 19:21:32'));
      expect(txn.source, 'HBL');
      expect(txn.type, 'card_charge');
      expect(txn.transactionId, isNotEmpty);
      expect(txn.subject, msg);
      expect(txn.beneficiary, isNull);
    });

    test('parses ATM withdrawal (pattern B) with comma amount', () {
      const msg =
          'Your HBL A/C 2456***76703 has been debited with PKR 5,000.00 on 12/02/2026 16:30:19 for ATM Cash Withdrawal.';
      final txn = service.parseHblSms(msg);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-5000.00, 0.001));
      expect(txn.date, formatter.parse('12/02/2026 16:30:19'));
      expect(txn.source, 'HBL');
      expect(txn.type, 'atm_withdrawal');
      expect(txn.beneficiary, 'ATM Cash Withdrawal');
      expect(txn.transactionId, isNotEmpty);
    });

    test('parses Raast received (pattern C)', () {
      const msg =
          'UMER, PKR 380.00 received from HUZAIFA BIN KHALID A/C via Raast on 10/02/2026 14:10:15, TXN ID SM1014095380DD53. UAN:021111111425.';
      final txn = service.parseHblSms(msg);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(380.00, 0.001));
      expect(txn.date, formatter.parse('10/02/2026 14:10:15'));
      expect(txn.source, 'HBL');
      expect(txn.type, 'raast_received');
      expect(txn.beneficiary, 'HUZAIFA BIN KHALID');
      expect(txn.transactionId, 'SM1014095380DD53');
    });

    test('returns null for unknown message', () {
      const msg = 'This is some other bank sms without pattern';
      final txn = service.parseHblSms(msg);
      expect(txn, isNull);
    });

    test('handles amount without decimal and multi-line SMS', () {
      const msg =
          'Your HBL Debit Card has been charged for a Transaction of PKR 1,234 on 01/01/2026 01:02:03.';
      final txn = service.parseHblSms(msg);
      expect(txn, isNotNull);
      expect(txn!.amount, closeTo(-1234.0, 0.001));

      const multi =
          'Your HBL A/C 1234 has been debited with PKR 2,500.00 on 02/02/2026 02:02:02\nfor ATM Cash Withdrawal.';
      final txn2 = service.parseHblSms(multi);
      expect(txn2, isNotNull);
      expect(txn2!.amount, closeTo(-2500.0, 0.001));
      expect(txn2.beneficiary, 'ATM Cash Withdrawal');
    });
  });
}
