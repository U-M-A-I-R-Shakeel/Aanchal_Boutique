import 'package:aanchal_boutique/core/notifications/notification_service.dart';

class ScheduledNotification {
  ScheduledNotification(this.id, this.title, this.body, this.at, this.payload);
  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String? payload;
}

/// Records what would be scheduled with the OS.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  final Map<int, ScheduledNotification> pending = {};

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {}

  @override
  Future<bool> launchedFromNotification() async => false;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    pending[id] = ScheduledNotification(id, title, body, at, payload);
  }

  @override
  Future<void> cancel(int id) async => pending.remove(id);

  @override
  Future<void> cancelAllPending() async => pending.clear();
}
