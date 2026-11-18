// Drives the app for the handover demo video (see README "Demo video").
// It pauses between steps so a screen recording is easy to follow.
//
// Uses its own database file, so the app's real data is never touched.
//
// The reminder for the demo booking would normally arrive 1 hour before the
// booking. To show it on camera, this script re-schedules that same reminder
// (same id, same text) to fire a few seconds later.
import 'package:aanchal_boutique/app.dart';
import 'package:aanchal_boutique/core/database/app_database.dart';
import 'package:aanchal_boutique/core/database/database_provider.dart';
import 'package:aanchal_boutique/core/notifications/local_notification_service.dart';
import 'package:aanchal_boutique/core/notifications/notification_provider.dart';
import 'package:aanchal_boutique/features/booking/data/sqlite_booking_repository.dart';
import 'package:aanchal_boutique/features/booking/domain/booking_reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('handover demo', (tester) async {
    Future<void> pause([double seconds = 2]) async {
      await Future<void>.delayed(
        Duration(milliseconds: (seconds * 1000).round()),
      );
      await tester.pump();
    }

    Future<void> tap(Finder f, [double wait = 2]) async {
      await tester.tap(f);
      await tester.pumpAndSettle();
      await pause(wait);
    }

    // Demo data: two bookings by other customers tomorrow.
    final path = p.join(await getDatabasesPath(), 'demo.db');
    await deleteDatabase(path);
    final db = await AppDatabase.open(path: path);
    final repo = SqliteBookingRepository(db);
    final now = DateTime.now();
    DateTime tomorrowAt(int h, [int m = 0]) =>
        DateTime(now.year, now.month, now.day + 1, h, m);
    await repo.create(
      roomId: 'room-1',
      start: tomorrowAt(11),
      customerName: 'Hira Malik',
      now: now,
    );
    final zara = await repo.create(
      roomId: 'room-3',
      start: tomorrowAt(15),
      customerName: 'Zara Ahmed',
      now: now,
    );

    final notifications = LocalNotificationService();
    await notifications.init(onTap: (_) {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const AanchalBoutiqueApp(),
      ),
    );
    await tester.pumpAndSettle();
    await pause(3);

    // 1. A busy room can't be booked.
    await tap(find.text('Room 2'), 2.5);

    // 2. Booking flow: name, date, time slot, confirm.
    await tap(find.text('Room 1'));
    await tester.enterText(
      find.byKey(const ValueKey('customer-name')),
      'Ayesha Khan',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await pause(1.5);
    await tap(find.byKey(const ValueKey('date-1')), 2);
    await tap(find.byKey(const ValueKey('slot-1030')), 2.5);
    await tap(find.text('Confirm Booking'), 3.5);

    // 3. Bookings list.
    await tap(find.byTooltip('Bookings'), 3);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await pause(1);

    // 4. Staff view: tomorrow's schedule.
    await tap(find.text('Staff'), 1.5);
    await tap(find.byTooltip('Next day'), 3);

    // 5. Reminder (fired early for the camera; normally 1 hour before).
    final ayesha = (await repo.getBookingsForDate(
      tomorrowAt(0),
    )).firstWhere((b) => b.customerName == 'Ayesha Khan');
    await notifications.schedule(
      id: ayesha.id,
      title: BookingReminders.title,
      body: BookingReminders.body('Room 1', ayesha.start),
      at: DateTime.now().add(const Duration(seconds: 6)),
      payload: BookingReminders.payload(ayesha),
    );
    await pause(12);

    // 6. Staff cancels a booking; the room's status updates.
    await tap(find.byKey(ValueKey('staff-cancel-${zara.id}')), 2);
    await tap(find.text('Cancel booking'), 3);
    await tap(find.text('Home'), 4);

    await db.close();
    await deleteDatabase(path);
  }, semanticsEnabled: false);
}
