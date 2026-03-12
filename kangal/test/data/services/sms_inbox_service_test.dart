import 'package:flutter_test/flutter_test.dart';
import 'package:telephony/telephony.dart';
import 'package:kangal/data/services/sms_inbox_service.dart';

/// A very small fake implementation of [SmsInboxProvider] that allows us to
/// drive the behaviour of the service under test.  The inbox can be primed
/// with a list of messages and the test can manually trigger the callbacks
/// which the service registered.
class FakeSmsInboxProvider implements SmsInboxProvider {
  List<SmsMessage> inbox = [];
  MessageHandler? _onNew;
  MessageHandler? _onBackground;

  @override
  Future<List<SmsMessage>> getInboxSms({
    List<SmsColumn> columns = DEFAULT_SMS_COLUMNS,
    SmsFilter? filter,
    List<OrderBy>? sortOrder,
  }) async {
    // we ignore the filter parameter since the service will apply its own
    // predicate; just return whatever inbox we currently have.
    return inbox;
  }

  @override
  void listenIncomingSms({
    required MessageHandler onNewMessage,
    MessageHandler? onBackgroundMessage,
    bool listenInBackground = true,
  }) {
    _onNew = onNewMessage;
    _onBackground = onBackgroundMessage;
  }

  /// Helpers used by tests to simulate incoming SMS events.
  void simulateForegroundSms(SmsMessage msg) {
    if (_onNew != null) _onNew!(msg);
  }

  void simulateBackgroundSms(SmsMessage msg) {
    if (_onBackground != null) _onBackground!(msg);
  }
}

/// Convenience helper for constructing a test [SmsMessage]. Only the fields
/// relevant to our service ({@code address} and {@code date}) are populated.
SmsMessage makeSms({
  required String address,
  required DateTime date,
  String? body,
}) {
  // ``fromMap`` is annotated ``@visibleForTesting`` in the telephony package,
  // but we are also in a test context so it's fine to use it here. We only
  // provide the columns that we care about.
  final map = <String, String>{
    'address': address,
    'body': body ?? '',
    'date': date.millisecondsSinceEpoch.toString(),
  };
  return SmsMessage.fromMap(map, [
    SmsColumn.ADDRESS,
    SmsColumn.BODY,
    SmsColumn.DATE,
  ]);
}

void main() {
  late FakeSmsInboxProvider fakeProvider;
  late SmsInboxService service;

  setUp(() {
    fakeProvider = FakeSmsInboxProvider();
    service = SmsInboxService(provider: fakeProvider);
  });

  group('getHblMessages', () {
    test('returns only messages with HBL sender and within cutoff', () async {
      final now = DateTime.now();
      fakeProvider.inbox = [
        makeSms(address: 'HBL BANK', date: now.subtract(Duration(days: 1))),
        makeSms(address: 'hblxyz', date: now.subtract(Duration(days: 10))),
        makeSms(address: 'other', date: now),
        makeSms(address: 'HBL OLD', date: now.subtract(Duration(days: 200))),
      ];

      final result = await service.getHblMessages(daysBack: 90);

      expect(result.length, 2);
      expect(result.any((m) => m.address == 'HBL BANK'), isTrue);
      expect(result.any((m) => m.address == 'hblxyz'), isTrue);
      expect(result.any((m) => m.address == 'other'), isFalse);
      expect(result.any((m) => m.address == 'HBL OLD'), isFalse);
    });

    test('defaults to 90 days when daysBack not provided', () async {
      final now = DateTime.now();
      fakeProvider.inbox = [
        makeSms(address: 'HBL', date: now.subtract(Duration(days: 89))),
        makeSms(address: 'HBL', date: now.subtract(Duration(days: 91))),
      ];
      final result = await service.getHblMessages();
      expect(result.length, 1);
    });

    test('returns empty list when inbox is empty', () async {
      fakeProvider.inbox = [];
      final result = await service.getHblMessages();
      expect(result, isEmpty);
    });
  });

  group('listenForNewSms', () {
    test('invokes callback for foreground HBL message only', () {
      SmsMessage? received;
      service.listenForNewSms((m) => received = m);

      // simulate messages from fake provider
      final msg1 = makeSms(address: 'hbl123', date: DateTime.now());
      final msg2 = makeSms(address: 'foo', date: DateTime.now());

      fakeProvider.simulateForegroundSms(msg1);
      fakeProvider.simulateForegroundSms(msg2);

      expect(received?.address, msg1.address);
      expect(received?.date, msg1.date);
    });

    test('invokes callback for background HBL message only', () {
      SmsMessage? received;
      service.listenForNewSms((m) => received = m);

      final msg1 = makeSms(address: 'HBL something', date: DateTime.now());
      final msg2 = makeSms(address: 'other', date: DateTime.now());

      fakeProvider.simulateBackgroundSms(msg2);
      expect(received, isNull);

      fakeProvider.simulateBackgroundSms(msg1);
      expect(received?.address, msg1.address);
      expect(received?.date, msg1.date);
    });
  });
}
