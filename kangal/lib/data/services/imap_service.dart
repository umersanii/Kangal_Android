import 'package:enough_mail/enough_mail.dart';
import 'package:intl/intl.dart';

/// A thin wrapper around the `enough_mail` IMAP client that knows how to
/// talk to Gmail and run the very specific search we need for NayaPay
/// transaction emails.
///
/// The implementation is intentionally small and the constructor accepts an
/// optional [ImapClient] instance to make testing easy. In production the
/// default client is used with logging disabled.
class ImapService {
  final String email;
  final String appPassword;
  final ImapClient _client;

  /// [email] and [appPassword] are the credentials for a Gmail account with
  /// an app password generated. The optional [client] parameter is used by
  /// tests; production code should omit it.
  ImapService({
    required this.email,
    required this.appPassword,
    ImapClient? client,
  }) : _client = client ?? ImapClient(isLogEnabled: false);

  /// Establishes a connection to Gmail's IMAP server and logs in. Throws on
  /// any failure.
  Future<void> connect() async {
    await _client.connectToServer('imap.gmail.com', 993, isSecure: true);
    await _client.login(email, appPassword);
  }

  /// Gracefully logs out and disconnects. Any error during logout is
  /// swallowed since the connection may already have been torn down.
  Future<void> disconnect() async {
    try {
      await _client.logout();
    } catch (_) {
      // ignore
    }
    await _client.disconnect();
  }

  /// Fetches all messages from the last [daysBack] days that came from
  /// `service@nayapay.com`. The returned list contains fully fetched
  /// `MimeMessage` objects (body + headers) ready for parsing by the
  /// [NayaPayEmailService].
  Future<List<MimeMessage>> fetchNayaPayEmails({int daysBack = 90}) async {
    await _client.selectInbox();

    final sinceDate = DateTime.now().subtract(Duration(days: daysBack));
    final sinceStr = DateFormat('d-MMM-yyyy').format(sinceDate);
    final criteria = 'FROM "service@nayapay.com" SINCE $sinceStr';

    final searchResult = await _client.searchMessages(searchCriteria: criteria);
    final seq = searchResult.matchingSequence;
    final messageIds = seq?.toList() ?? <int>[];

    final messages = <MimeMessage>[];
    for (final messageId in messageIds) {
      final fetchResult = await _client.fetchMessage(messageId, 'BODY[]');
      if (fetchResult.messages.isNotEmpty) {
        messages.add(fetchResult.messages.first);
      }
    }

    return messages;
  }

  /// Convenience method used by UI/code during setup to verify credentials.
  /// Returns `true` if a connection can be established and torn down
  /// without throwing.
  Future<bool> testConnection() async {
    try {
      await connect();
      await disconnect();
      return true;
    } catch (_) {
      return false;
    }
  }
}
