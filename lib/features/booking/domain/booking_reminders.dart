import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/formatters.dart';
import 'models/booking.dart';

/// Schedules a local notification 1 hour before each booking.
///
/// The booking's database id is used as the notification id, so a reminder
/// can be cancelled together with its booking.
class BookingReminders {
  BookingReminders(this._notifications);

  final NotificationService _notifications;

  static const leadTime = Duration(hours: 1);

  /// iOS keeps at most 64 pending notifications per app.
  static const maxPending = 60;

  static const title = 'Your fitting is in 1 hour';

  static DateTime fireTime(Booking booking) => booking.start.subtract(leadTime);

  /// e.g. "Fitting Room 2 at 3:00 PM"
  static String body(String roomName, DateTime start) =>
      'Fitting $roomName at ${Formatters.time(start)}';

  static String payload(Booking booking) => 'booking:${booking.id}';

  static bool _due(Booking b, DateTime now) =>
      b.isConfirmed && fireTime(b).isAfter(now);

  /// Asks for permission if needed and schedules the reminder. Returns false
  /// (and schedules nothing) if the reminder time has already passed, e.g.
  /// for a booking less than an hour away, or if permission was refused.
  Future<bool> schedule(
    Booking booking, {
    required String roomName,
    required DateTime now,
  }) async {
    if (!_due(booking, now)) return false;
    if (!await _notifications.requestPermission()) return false;
    await _notify(booking, roomName);
    return true;
  }

  Future<void> cancel(Booking booking) => _notifications.cancel(booking.id);

  /// Rebuilds all pending reminders from the bookings in the database, so
  /// they stay correct after a reinstall, a restore or a cancelled booking.
  /// Doesn't ask for permission.
  Future<void> resync(
    List<Booking> bookings, {
    required Map<String, String> roomNames,
    required DateTime now,
  }) async {
    await _notifications.cancelAllPending();
    final due = bookings.where((b) => _due(b, now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final b in due.take(maxPending)) {
      await _notify(b, roomNames[b.roomId] ?? b.roomId);
    }
  }

  Future<void> _notify(Booking b, String roomName) => _notifications.schedule(
    id: b.id,
    title: title,
    body: body(roomName, b.start),
    at: fireTime(b),
    payload: payload(b),
  );
}

/// Runs [action] without letting a notification problem break the caller:
/// a booking is already saved by the time its reminder is handled.
Future<T?> bestEffort<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    debugPrint('Reminder error: $e\n$st');
    return null;
  }
}
