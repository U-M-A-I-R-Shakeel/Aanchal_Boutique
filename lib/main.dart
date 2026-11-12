import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/navigation/app_navigator.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/notification_provider.dart';
import 'core/utils/clock.dart';
import 'features/booking/presentation/providers/bookings_provider.dart';
import 'features/booking/presentation/screens/bookings_screen.dart';
import 'features/home/presentation/providers/rooms_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();

  final notifications = LocalNotificationService();
  await notifications.init(onTap: (_) => _openBookings());
  final launchedFromReminder = await notifications.launchedFromNotification();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
  );
  unawaited(_resyncReminders(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AanchalBoutiqueApp(),
    ),
  );

  if (launchedFromReminder) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBookings());
  }
}

/// Tapping a reminder opens the app on the Bookings screen.
void _openBookings() => appNavigatorKey.currentState?.push(
  MaterialPageRoute<void>(builder: (_) => const BookingsScreen()),
);

Future<void> _resyncReminders(ProviderContainer container) async {
  try {
    final rooms = await container.read(roomsProvider.future);
    final bookings = await container.read(bookingsProvider.future);
    await container
        .read(bookingRemindersProvider)
        .resync(
          bookings,
          roomNames: {for (final r in rooms) r.id: r.name},
          now: container.read(clockProvider)(),
        );
  } catch (e) {
    debugPrint('Could not resync reminders: $e');
  }
}
