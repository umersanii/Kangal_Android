import 'package:permission_handler/permission_handler.dart';

/// A minimal abstraction around permission operations so that the
/// production code can use `permission_handler` while tests can inject
/// a fake implementation without invoking platform channels.
abstract class PermissionHandler {
  Future<PermissionStatus> request();
  Future<PermissionStatus> get status;
}

class _DefaultPermissionHandler implements PermissionHandler {
  final Permission _permission;
  _DefaultPermissionHandler(this._permission);

  @override
  Future<PermissionStatus> request() => _permission.request();

  @override
  Future<PermissionStatus> get status => _permission.status;
}

/// A thin wrapper around the `permission_handler` package that exposes
/// the specific permission operations our app needs. The class is kept
/// simple but is also built to be testable by allowing a fake
/// [PermissionHandler] instance and an injectable `openAppSettings` callback.
class SmsPermissionService {
  final PermissionHandler _handler;
  final Future<bool> Function() _openSettings;

  /// [handler] and [openSettings] are primarily provided to make the
  /// class easier to mock in tests; production code can simply rely on the
  /// defaults which delegate to `Permission.sms` and the top-level
  /// `openAppSettings`.
  SmsPermissionService({
    PermissionHandler? handler,
    Future<bool> Function()? openSettings,
  })  : _handler = handler ?? _DefaultPermissionHandler(Permission.sms),
        _openSettings = openSettings ?? _defaultOpenSettings;

  /// Requests the SMS permission from the user.
  ///
  /// Returns `true` if the permission ended up being granted. If the user
  /// denies or permanently denies the permission the method returns `false`.
  /// Consumers can choose to call [openAppSettings] in the permanently
  /// denied case if they want to direct the user to settings.
  Future<bool> requestSmsPermission() async {
    final status = await _handler.request();
    if (status.isGranted) {
      return true;
    }

    // For denied or permanentlyDenied we simply return false. The caller
    // may opt to guide the user to app settings separately.
    return false;
  }

  /// Returns `true` when the SMS permission has already been granted.
  Future<bool> isSmsPermissionGranted() async {
    final status = await _handler.status;
    return status.isGranted;
  }

  /// Opens the platform-specific settings screen for this app. The return
  /// value is `true` if the settings screen could be opened, `false`
  /// otherwise.
  Future<bool> openAppSettings() => _openSettings();
}

// Top-level helper that simply delegates to the permission_handler's
// `openAppSettings` function. We keep it separate so that it can be
// referenced from a constructor initializer without colliding with the
// instance method of the same name.
Future<bool> _defaultOpenSettings() => openAppSettings();
