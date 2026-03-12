import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail/src/private/util/client_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kangal/data/services/imap_service.dart';

/// A very small fake implementation of [ImapClient] that only implements the
/// handful of methods used by [ImapService]. It also exposes a few flags and
/// helpers so that the tests can assert that the correct calls were made.
class _FakeImapClient extends ImapClient {
  _FakeImapClient() : super(isLogEnabled: false);

  bool connectCalled = false;
  bool loginCalled = false;
  bool logoutCalled = false;
  bool disconnectCalled = false;
  bool inboxSelected = false;
  String? lastSearchCriteria;

  /// What the fake will return from [searchMessages].
  List<int> uidsToReturn = [];
  final Map<int, MimeMessage> messages = {};

  @override
  Future<ConnectionInfo> connectToServer(
    String host,
    int port, {
    bool isSecure = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    connectCalled = true;
    return ConnectionInfo(host, port, isSecure: isSecure);
  }

  @override
  Future<List<Capability>> login(String name, String password) async {
    loginCalled = true;
    return <Capability>[];
  }

  @override
  Future<Mailbox> selectInbox({
    bool enableCondStore = false,
    QResyncParameters? qresync,
  }) async {
    inboxSelected = true;
    return Mailbox(
      encodedName: 'INBOX',
      encodedPath: 'INBOX',
      flags: [MailboxFlag.inbox],
      pathSeparator: '/',
    );
  }

  @override
  Future<SearchImapResult> searchMessages({
    String searchCriteria = 'UNSEEN',
    List<ReturnOption>? returnOptions,
    Duration? responseTimeout,
  }) async {
    lastSearchCriteria = searchCriteria;
    final result = SearchImapResult();
    if (uidsToReturn.isNotEmpty) {
      result.matchingSequence = MessageSequence.fromIds(
        uidsToReturn,
        isUid: true,
      );
    }
    return result;
  }

  @override
  Future<FetchImapResult> fetchMessage(
    int messageSequenceId,
    String fetchContentDefinition, {
    Duration? responseTimeout,
  }) async {
    return FetchImapResult([
      messages[messageSequenceId] ?? MimeMessage(),
    ], null);
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }
}

class _ThrowingConnectClient extends _FakeImapClient {
  @override
  Future<ConnectionInfo> connectToServer(
    String host,
    int port, {
    bool isSecure = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    throw Exception('cannot connect');
  }
}

void main() {
  group('ImapService', () {
    late _FakeImapClient fakeClient;
    late ImapService service;

    setUp(() {
      fakeClient = _FakeImapClient();
      service = ImapService(
        email: 'test@example.com',
        appPassword: 'app-pass',
        client: fakeClient,
      );
    });

    test('connect calls connectToServer and login', () async {
      await service.connect();
      expect(fakeClient.connectCalled, isTrue);
      expect(fakeClient.loginCalled, isTrue);
    });

    test('disconnect calls logout and disconnect', () async {
      await service.disconnect();
      expect(fakeClient.logoutCalled, isTrue);
      expect(fakeClient.disconnectCalled, isTrue);
    });

    test('testConnection returns true when no error thrown', () async {
      final result = await service.testConnection();
      expect(result, isTrue);
      expect(fakeClient.connectCalled, isTrue);
      expect(fakeClient.logoutCalled, isTrue);
    });

    test('testConnection returns false when connect throws', () async {
      final brokenClient = _ThrowingConnectClient();
      final broken = ImapService(
        email: 'a',
        appPassword: 'b',
        client: brokenClient,
      );

      final result = await broken.testConnection();
      expect(result, isFalse);
    });

    test(
      'fetchNayaPayEmails selects inbox and runs appropriate search',
      () async {
        // prepare fake uids and messages
        fakeClient.uidsToReturn = [5, 7];
        final msg1 = MimeMessage();
        final msg2 = MimeMessage();
        fakeClient.messages[5] = msg1;
        fakeClient.messages[7] = msg2;

        final now = DateTime.now();
        final daysBack = 30;
        final emails = await service.fetchNayaPayEmails(daysBack: daysBack);

        expect(fakeClient.inboxSelected, isTrue);
        expect(fakeClient.lastSearchCriteria, isNotNull);
        expect(
          fakeClient.lastSearchCriteria!,
          contains('FROM "service@nayapay.com"'),
        );
        // check SINCE date is roughly correct
        final expectedSince = DateFormat(
          'd-MMM-yyyy',
        ).format(now.subtract(Duration(days: daysBack)));
        expect(
          fakeClient.lastSearchCriteria!,
          contains('SINCE $expectedSince'),
        );

        expect(emails, [msg1, msg2]);
      },
    );
  });
}
