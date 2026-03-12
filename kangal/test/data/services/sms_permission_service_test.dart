import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kangal/data/services/sms_permission_service.dart';

/// Simple fake implementation of [PermissionHandler] used in tests. The
/// caller may set the next response for `request` or `status` directly.
class FakePermissionHandler implements PermissionHandler {
  PermissionStatus? nextRequestStatus;
  PermissionStatus? nextStatus;

  @override
  Future<PermissionStatus> request() async {
    return nextRequestStatus ?? PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> get status async {
    return nextStatus ?? PermissionStatus.denied;
  }
}

void main() {
  late FakePermissionHandler fakeHandler;
  late SmsPermissionService service;
  late bool openSettingsCalled;

  setUp(() {
    fakeHandler = FakePermissionHandler();
    openSettingsCalled = false;
    service = SmsPermissionService(
      handler: fakeHandler,
      openSettings: () async {
        openSettingsCalled = true;
        return true;
      },
    );
  });

  group('requestSmsPermission', () {
    test('returns true when permission granted', () async {
      fakeHandler.nextRequestStatus = PermissionStatus.granted;

      final result = await service.requestSmsPermission();

      expect(result, isTrue);
    });

    test('returns false when permission denied', () async {
      fakeHandler.nextRequestStatus = PermissionStatus.denied;

      final result = await service.requestSmsPermission();

      expect(result, isFalse);
    });

    test('returns false when permission permanently denied', () async {
      fakeHandler.nextRequestStatus = PermissionStatus.permanentlyDenied;

      final result = await service.requestSmsPermission();

      expect(result, isFalse);
    });
  });

  group('isSmsPermissionGranted', () {
    test('true when status is granted', () async {
      fakeHandler.nextStatus = PermissionStatus.granted;

      final result = await service.isSmsPermissionGranted();
      expect(result, isTrue);
    });

    test('false when status is denied', () async {
      fakeHandler.nextStatus = PermissionStatus.denied;

      final result = await service.isSmsPermissionGranted();
      expect(result, isFalse);
    });

    test('false when status is permanentlyDenied', () async {
      fakeHandler.nextStatus = PermissionStatus.permanentlyDenied;

      final result = await service.isSmsPermissionGranted();
      expect(result, isFalse);
    });
  });

  test('openAppSettings delegates to provided callback', () async {
    final result = await service.openAppSettings();
    expect(result, isTrue);
    expect(openSettingsCalled, isTrue);
  });
}
