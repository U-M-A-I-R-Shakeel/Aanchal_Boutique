import 'dart:io';

import 'package:aanchal_boutique/core/database/app_database.dart';
import 'package:aanchal_boutique/features/booking/data/sqlite_booking_repository.dart';
import 'package:aanchal_boutique/features/booking/domain/booking_exception.dart';
import 'package:aanchal_boutique/features/home/data/sqlite_room_repository.dart';
import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Uses a real database file and reopens it, like an app restart.
void main() {
  sqfliteFfiInit();
  late String path;

  setUp(() {
    final dir = Directory.systemTemp.createTempSync('aanchal_db_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    path = p.join(dir.path, AppDatabase.fileName);
  });

  Future<Database> open() =>
      AppDatabase.open(path: path, factory: databaseFactoryFfi);

  Future<Map<String, RoomStatus>> statuses(Database db, DateTime now) async => {
    for (final r in await SqliteRoomRepository(db).getRooms(now: now))
      r.id: r.status,
  };

  final today = DateTime(2026, 11, 10, 9);
  final tomorrow = DateTime(2026, 11, 11, 9);

  test('fresh database is seeded with three rooms', () async {
    final db = await open();
    expect(await statuses(db, today), {
      'room-1': RoomStatus.available,
      'room-2': RoomStatus.busy,
      'room-3': RoomStatus.available,
    });
    expect(await SqliteBookingRepository(db).getBookings(), isEmpty);
    await db.close();
  });

  test('bookings and room status survive a restart', () async {
    var db = await open();
    final created = await SqliteBookingRepository(db).create(
      roomId: 'room-1',
      start: DateTime(2026, 11, 10, 15, 30),
      customerName: 'Ayesha',
      now: today,
    );
    await db.close();

    // Reopen ("restart") the same day.
    db = await open();
    final bookings = await SqliteBookingRepository(db).getBookings();
    expect(bookings, [created]);
    expect(bookings.single.customerName, 'Ayesha');
    expect(bookings.single.start, DateTime(2026, 11, 10, 15, 30));
    expect((await statuses(db, today))['room-1'], RoomStatus.booked);
    await db.close();

    // Reopen the next day: yesterday's booking is still there, and the room
    // is available again because that slot has ended.
    db = await open();
    expect(await SqliteBookingRepository(db).getBookings(), [created]);
    expect((await statuses(db, tomorrow))['room-1'], RoomStatus.available);
    await db.close();
  });

  test(
    'cancelling deletes the row, frees the room, survives restart',
    () async {
      var db = await open();
      final repo = SqliteBookingRepository(db);
      final slot = DateTime(2026, 11, 12, 12);
      final b = await repo.create(
        roomId: 'room-3',
        start: slot,
        customerName: 'Hira',
        now: today,
      );
      expect((await statuses(db, today))['room-3'], RoomStatus.booked);

      await repo.cancel(b, now: today);
      await expectLater(
        repo.cancel(b, now: today),
        throwsA(isA<BookingException>()),
      );
      expect(await db.query('bookings'), isEmpty);
      await db.close();

      db = await open();
      expect(await SqliteBookingRepository(db).getBookings(), isEmpty);
      expect((await statuses(db, today))['room-3'], RoomStatus.available);

      // The freed slot can be booked again.
      await SqliteBookingRepository(
        db,
      ).create(roomId: 'room-3', start: slot, customerName: 'Sana', now: today);
      await db.close();
    },
  );

  test('cancelling one of two bookings keeps the room booked', () async {
    final db = await open();
    final repo = SqliteBookingRepository(db);
    final first = await repo.create(
      roomId: 'room-1',
      start: DateTime(2026, 11, 12, 12),
      customerName: 'A',
      now: today,
    );
    await repo.create(
      roomId: 'room-1',
      start: DateTime(2026, 11, 13, 12),
      customerName: 'B',
      now: today,
    );
    await repo.cancel(first, now: today);
    expect((await statuses(db, today))['room-1'], RoomStatus.booked);
    await db.close();
  });

  test('getBookingsForDate returns only that day, sorted by time', () async {
    final db = await open();
    final repo = SqliteBookingRepository(db);
    Future<void> add(String room, DateTime start, String name) =>
        repo.create(roomId: room, start: start, customerName: name, now: today);
    await add('room-3', DateTime(2026, 11, 12, 15), 'Late');
    await add('room-1', DateTime(2026, 11, 12, 10, 30), 'Early');
    await add('room-1', DateTime(2026, 11, 13, 10), 'Other day');

    final day = await repo.getBookingsForDate(DateTime(2026, 11, 12));
    expect(day.map((b) => b.customerName), ['Early', 'Late']);
    expect(await repo.getBookingsForDate(DateTime(2026, 11, 14)), isEmpty);
    await db.close();
  });

  test('database rejects a second confirmed booking for a slot', () async {
    final db = await open();
    final repo = SqliteBookingRepository(db);
    final slot = DateTime(2026, 11, 12, 12);
    await repo.create(
      roomId: 'room-1',
      start: slot,
      customerName: 'A',
      now: today,
    );
    await expectLater(
      repo.create(roomId: 'room-1', start: slot, customerName: 'B', now: today),
      throwsA(isA<BookingException>()),
    );
    await expectLater(
      repo.create(roomId: 'room-2', start: slot, customerName: 'C', now: today),
      throwsA(isA<BookingException>()),
    );
    expect(await repo.getBookings(), hasLength(1));
    await db.close();
  });
}
