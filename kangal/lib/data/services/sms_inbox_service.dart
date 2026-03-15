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
/// new messages.
class SmsInboxService {
  final SmsInboxProvider _provider;

  SmsInboxService({SmsInboxProvider? provider})
    : _provider = provider ?? TelephonySmsInboxProvider();

  /// Returns inbox messages used for historical import.
  ///
  /// When [daysBack] is provided, the result is additionally constrained to
  /// messages within that many days from now. If omitted, no date cutoff is
  /// applied and the full available history is returned.
  Future<List<SmsMessage>> getHblMessages({int? daysBack}) async {
    final cutoff = daysBack == null
        ? null
        : DateTime.now().subtract(Duration(days: daysBack)).millisecondsSinceEpoch;

    // We avoid sender/body pre-filtering here and let the parser stage decide
    // whether a message is a supported HBL transaction format.
    final raw = await _provider.getInboxSms(
      columns: const [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    return raw
        .where((m) {
          final date = m.date ?? 0;
          final passesCutoff = cutoff == null || date >= cutoff;
          return passesCutoff;
        })
        .toList(growable: false);
  }

  /// Registers a listener that will be invoked every time a new SMS arrives
  /// (foreground or background).
  ///
  /// Note that the callback may be called on a background isolate when
  /// [telephony] delivers messages while the app is not running; the caller
  /// should take care to perform any heavy work accordingly.
  void listenForNewSms(void Function(SmsMessage) onMessage) {
    _provider.listenIncomingSms(
      onNewMessage: (msg) {
        onMessage(msg);
      },
      onBackgroundMessage: (msg) {
        onMessage(msg);
      },
      listenInBackground: true,
    );
  }
}
