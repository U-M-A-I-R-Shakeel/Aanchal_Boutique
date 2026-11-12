import 'package:aanchal_boutique/core/database/app_database.dart';
import 'package:aanchal_boutique/core/database/database_provider.dart';
import 'package:aanchal_boutique/core/notifications/notification_provider.dart';
import 'package:aanchal_boutique/core/utils/clock.dart';
import 'package:aanchal_boutique/core/utils/formatters.dart';
import 'package:aanchal_boutique/features/booking/domain/booking_reminders.dart';
import 'package:aanchal_boutique/features/booking/domain/models/booking.dart';
import 'package:aanchal_boutique/features/booking/presentation/providers/bookings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 10, 9);

  group('BookingReminders', () {
    late FakeNotificationService fake;
    late BookingReminders reminders;

    setUp(() {
      fake = FakeNotificationService();
      reminders = BookingReminders(fake);
    });

    test('fires exactly 1 hour before, with room and time', () async {
      final b = fakeBooking(7, 'room-2', DateTime(2026, 11, 10, 15));
      expect(await reminders.schedule(b, roomName: 'Room 2', now: now), isTrue);

      final n = fake.pending[7]!;
      expect(n.at, DateTime(2026, 11, 10, 14));
      expect(
        n.body,
        'Fitting Room 2 at ${Formatters.time(DateTime(2026, 11, 10, 15))}',
      );
      expect(n.body, startsWith('Fitting Room 2 at 3:00'));
      expect(n.title, 'Your fitting is in 1 hour');
      expect(n.payload, 'booking:7');
    });

    test('works across midnight and month end', () async {
      final b = fakeBooking(8, 'room-1', DateTime(2026, 12, 1, 10, 30));
      await reminders.schedule(b, roomName: 'Room 1', now: now);
      expect(fake.pending[8]!.at, DateTime(2026, 12, 1, 9, 30));
    });

    test('no reminder when the booking is less than an hour away', () async {
      final b = fakeBooking(9, 'room-1', DateTime(2026, 11, 10, 9, 30));
      expect(
        await reminders.schedule(b, roomName: 'Room 1', now: now),
        isFalse,
      );
      expect(fake.pending, isEmpty);
      expect(fake.permissionRequests, 0);
    });

    test('nothing is scheduled if permission is refused', () async {
      fake.permissionGranted = false;
      final b = fakeBooking(10, 'room-1', DateTime(2026, 11, 10, 15));
      expect(
        await reminders.schedule(b, roomName: 'Room 1', now: now),
        isFalse,
      );
      expect(fake.pending, isEmpty);
    });

    test(
      'resync keeps only upcoming confirmed bookings, soonest first',
      () async {
        fake.pending[99] = ScheduledNotification(99, 't', 'b', now, null);
        await reminders.resync(
          [
            fakeBooking(1, 'room-1', DateTime(2026, 11, 9, 15)), // past
            fakeBooking(2, 'room-3', DateTime(2026, 11, 11, 12)),
            fakeBooking(3, 'room-1', DateTime(2026, 11, 10, 9, 30)), // < 1 h
            fakeBooking(
              4,
              'room-1',
              DateTime(2026, 11, 12, 10),
              status: BookingStatus.cancelled,
            ),
          ],
          roomNames: {'room-1': 'Room 1', 'room-3': 'Room 3'},
          now: now,
        );
        expect(fake.pending.keys, [2]);
        expect(fake.pending[2]!.at, DateTime(2026, 11, 11, 11));
        expect(fake.pending[2]!.body, startsWith('Fitting Room 3 at 12:00'));
        expect(fake.permissionRequests, 0);
      },
    );

    test('resync respects the iOS pending limit', () async {
      final many = [
        for (var i = 0; i < 80; i++)
          fakeBooking(
            i + 1,
            'room-1',
            DateTime(2026, 11, 11, 10).add(Duration(minutes: 30 * i)),
          ),
      ];
      await reminders.resync(many, roomNames: {}, now: now);
      expect(fake.pending, hasLength(BookingReminders.maxPending));
      expect(fake.pending.keys, contains(1));
      expect(fake.pending.keys, isNot(contains(80)));
    });
  });

  group('booking flow with a real database', () {
    sqfliteFfiInit();

    test('booking schedules a reminder; cancelling removes it', () async {
      final db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final fake = FakeNotificationService();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          notificationServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final notifier = container.read(bookingsProvider.notifier);

      final b = await notifier.book(
        roomId: 'room-3',
        start: DateTime(2026, 11, 10, 15),
        customerName: 'Ayesha',
      );
      expect(fake.pending[b.id]!.at, DateTime(2026, 11, 10, 14));
      expect(fake.pending[b.id]!.body, startsWith('Fitting Room 3 at 3:00'));

      await notifier.cancel(b);
      expect(fake.pending, isEmpty);
    });

    test('a notification failure does not lose the booking', () async {
      final db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          notificationServiceProvider.overrideWithValue(_ThrowingService()),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final b = await container
          .read(bookingsProvider.notifier)
          .book(
            roomId: 'room-1',
            start: DateTime(2026, 11, 10, 15),
            customerName: 'Hira',
          );
      expect(await container.read(bookingsProvider.future), [b]);
    });
  });
}

class _ThrowingService extends FakeNotificationService {
  @override
  Future<bool> requestPermission() => throw Exception('plugin unavailable');
}
