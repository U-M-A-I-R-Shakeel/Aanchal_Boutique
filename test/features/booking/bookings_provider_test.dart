import 'package:aanchal_boutique/core/database/app_database.dart';
import 'package:aanchal_boutique/core/database/database_provider.dart';
import 'package:aanchal_boutique/core/utils/clock.dart';
import 'package:aanchal_boutique/features/booking/presentation/providers/bookings_provider.dart';
import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:aanchal_boutique/features/home/presentation/providers/rooms_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Providers wired to a real (in-memory) SQLite database.
void main() {
  sqfliteFfiInit();
  late ProviderContainer container;

  Future<ProviderContainer> makeContainer(DateTime now) async {
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    return c;
  }

  setUp(() async => container = await makeContainer(DateTime(2026, 11, 10, 9)));

  BookingsNotifier notifier() => container.read(bookingsProvider.notifier);
  Future<RoomStatus> statusOf(String id) async => (await container.read(
    roomsProvider.future,
  )).firstWhere((r) => r.id == id).status;

  test('booking a free slot saves it and marks the room booked', () async {
    final slot = DateTime(2026, 11, 10, 15);
    final b = await notifier().book(
      roomId: 'room-1',
      start: slot,
      customerName: ' Ayesha ',
    );

    expect(b.customerName, 'Ayesha');
    expect(notifier().isSlotTaken('room-1', slot), isTrue);
    expect(container.read(bookedSlotsProvider('room-1')), contains(slot));
    expect(await statusOf('room-1'), RoomStatus.booked);
    expect(await statusOf('room-3'), RoomStatus.available);
  });

  test('double-booking the same slot is rejected', () async {
    final slot = DateTime(2026, 11, 12, 16, 30);
    await notifier().book(roomId: 'room-1', start: slot, customerName: 'A');
    await expectLater(
      notifier().book(roomId: 'room-1', start: slot, customerName: 'B'),
      throwsA(isA<BookingException>()),
    );
    expect((await container.read(bookingsProvider.future)), hasLength(1));
  });

  test('same slot in a different room is still bookable', () async {
    final slot = DateTime(2026, 11, 10, 11);
    await notifier().book(roomId: 'room-1', start: slot, customerName: 'A');
    await notifier().book(roomId: 'room-3', start: slot, customerName: 'B');
    expect(await statusOf('room-3'), RoomStatus.booked);
  });

  test(
    'empty name, past, off-grid and busy-room bookings are rejected',
    () async {
      final c = await makeContainer(DateTime(2026, 11, 10, 14));
      final n = c.read(bookingsProvider.notifier);
      Future<void> rejects(String room, DateTime start, [String name = 'A']) =>
          expectLater(
            n.book(roomId: room, start: start, customerName: name),
            throwsA(isA<BookingException>()),
          );

      await rejects('room-1', DateTime(2026, 11, 11, 10), '   ');
      await rejects('room-1', DateTime(2026, 11, 10, 13));
      await rejects('room-1', DateTime(2026, 11, 11, 18));
      await rejects('room-2', DateTime(2026, 11, 11, 10));
      expect(await c.read(bookingsProvider.future), isEmpty);
    },
  );

  test('cancel frees the slot and the room', () async {
    final slot = DateTime(2026, 11, 11, 10);
    final b = await notifier().book(
      roomId: 'room-1',
      start: slot,
      customerName: 'A',
    );
    await notifier().cancel(b);

    expect(notifier().isSlotTaken('room-1', slot), isFalse);
    expect(await statusOf('room-1'), RoomStatus.available);

    // The cancelled slot can be booked again.
    await notifier().book(roomId: 'room-1', start: slot, customerName: 'B');
    expect(await statusOf('room-1'), RoomStatus.booked);
  });
}
