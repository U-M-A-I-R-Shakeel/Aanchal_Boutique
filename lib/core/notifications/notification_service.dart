/// Local (on-device) notifications, behind an interface so the rest of the
/// app and the tests don't depend on the plugin.
abstract interface class NotificationService {
  /// Sets up the plugin. [onTap] runs when the user taps a notification while
  /// the app is running (in the foreground or background).
  Future<void> init({required void Function(String? payload) onTap});

  /// Whether the app was just launched by tapping one of our notifications.
  Future<bool> launchedFromNotification();

  /// Asks the OS for permission to show notifications. Returns whether it is
  /// granted. Only prompts the first time.
  Future<bool> requestPermission();

  /// Shows a notification at [at] (local time). Replaces any pending
  /// notification with the same [id].
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  });

  Future<void> cancel(int id);

  /// Cancels every scheduled (not yet shown) notification.
  Future<void> cancelAllPending();
}
