import 'package:telephony/telephony.dart';

/// Abstraction over the platform SMS APIs exposed by the `telephony` package.
///
/// The interface is intentionally very small so that the production code can
/// simply delegate to [Telephony] while tests are free to provide a lightweight
/// fake implementation. This keeps the service easy to unit test without
/// needing the real Android SMS machinery.
abstract class SmsInboxProvider {
  Future<List<SmsMessage>> getInboxSms({
    List<SmsColumn> columns,
    SmsFilter? filter,
    List<OrderBy>? sortOrder,
  });

  void listenIncomingSms({
    required MessageHandler onNewMessage,
    MessageHandler? onBackgroundMessage,
    bool listenInBackground,
  });
}

/// Default implementation of [SmsInboxProvider] backed by the real
/// `telephony.Telephony` singleton.
class TelephonySmsInboxProvider implements SmsInboxProvider {
  final Telephony _telephony;

  TelephonySmsInboxProvider([Telephony? telephony])
    : _telephony = telephony ?? Telephony.instance;

  @override
  Future<List<SmsMessage>> getInboxSms({
    List<SmsColumn> columns = const [],
    SmsFilter? filter,
    List<OrderBy>? sortOrder,
  }) {
    return _telephony.getInboxSms(
      columns: columns,
      filter: filter,
      sortOrder: sortOrder,
    );
  }

  @override
  void listenIncomingSms({
    required MessageHandler onNewMessage,
    MessageHandler? onBackgroundMessage,
    bool listenInBackground = true,
  }) {
    _telephony.listenIncomingSms(
      onNewMessage: onNewMessage,
      onBackgroundMessage: onBackgroundMessage,
      listenInBackground: listenInBackground,
    );
  }
}

/// Service responsible for reading the SMS inbox and registering listeners for
/// new messages. The class filters results to only include messages that
/// appear to originate from HBL (sender address contains the substring "HBL",
/// case‑insensitive).
class SmsInboxService {
  final SmsInboxProvider _provider;

  SmsInboxService({SmsInboxProvider? provider})
    : _provider = provider ?? TelephonySmsInboxProvider();

  /// Returns all inbox messages that look like they came from HBL and whose
  /// date is within the past [daysBack] days. The default window of 90 days is
  /// chosen to match the requirements of TASK-017.
  Future<List<SmsMessage>> getHblMessages({int daysBack = 90}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysBack))
        .millisecondsSinceEpoch;

    // We still pass a filter to the underlying API to narrow the results, but
    // perform an additional check in Dart to ensure case‑insensitivity and to
    // apply the date cutoff since the filter builder is fairly limited.
    final raw = await _provider.getInboxSms(
      filter: SmsFilter.where(SmsColumn.ADDRESS).like('%HBL%'),
    );

    return raw
        .where((m) {
          final addr = m.address?.toLowerCase() ?? '';
          final date = m.date ?? 0;
          return addr.contains('hbl') && date >= cutoff;
        })
        .toList(growable: false);
  }

  /// Registers a listener that will be invoked every time a new SMS arrives
  /// (foreground or background) and the sender address contains "HBL".
  ///
  /// Note that the callback may be called on a background isolate when
  /// [telephony] delivers messages while the app is not running; the caller
  /// should take care to perform any heavy work accordingly.
  void listenForNewSms(void Function(SmsMessage) onMessage) {
    _provider.listenIncomingSms(
      onNewMessage: (msg) {
        final addr = msg.address?.toLowerCase() ?? '';
        if (addr.contains('hbl')) {
          onMessage(msg);
        }
      },
      onBackgroundMessage: (msg) {
        final addr = msg.address?.toLowerCase() ?? '';
        if (addr.contains('hbl')) {
          onMessage(msg);
        }
      },
      listenInBackground: true,
    );
  }
}
