import 'package:aanchal_boutique/core/utils/clock.dart';
import 'package:aanchal_boutique/features/booking/presentation/providers/bookings_provider.dart';
import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:aanchal_boutique/features/home/presentation/providers/rooms_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  final now = DateTime(2026, 11, 10, 9);

  setUp(() {
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
  });

  BookingsNotifier notifier() => container.read(bookingsProvider.notifier);
  RoomStatus statusOf(String id) =>
      container.read(roomsProvider).firstWhere((r) => r.id == id).status;

  test('booking a free slot stores it and marks the room booked', () {
    final slot = DateTime(2026, 11, 10, 15);
    expect(notifier().isSlotTaken('room-1', slot), isFalse);

    notifier().book(roomId: 'room-1', start: slot);

    expect(notifier().isSlotTaken('room-1', slot), isTrue);
    expect(container.read(bookedSlotsProvider('room-1')), contains(slot));
    expect(statusOf('room-1'), RoomStatus.booked);
    expect(statusOf('room-3'), RoomStatus.available);
  });

  test('booking an already-booked slot is rejected', () {
    // Seeded booking: room-1 today at 11:00.
    expect(
      () =>
          notifier().book(roomId: 'room-1', start: DateTime(2026, 11, 10, 11)),
      throwsA(isA<BookingException>()),
    );
    expect(statusOf('room-1'), RoomStatus.available);
  });

  test('same slot in a different room is still bookable', () {
    notifier().book(roomId: 'room-3', start: DateTime(2026, 11, 10, 11));
    expect(statusOf('room-3'), RoomStatus.booked);
  });

  test('double-booking the same slot is rejected', () {
    final slot = DateTime(2026, 11, 12, 16, 30);
    notifier().book(roomId: 'room-1', start: slot);
    expect(
      () => notifier().book(roomId: 'room-1', start: slot),
      throwsA(isA<BookingException>()),
    );
  });

  test('past, off-grid and busy-room bookings are rejected', () {
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 14)),
      ],
    );
    addTearDown(c.dispose);
    final n = c.read(bookingsProvider.notifier);

    expect(
      () => n.book(roomId: 'room-1', start: DateTime(2026, 11, 10, 13)),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => n.book(roomId: 'room-1', start: DateTime(2026, 11, 11, 18)),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => n.book(roomId: 'room-2', start: DateTime(2026, 11, 11, 10)),
      throwsA(isA<BookingException>()),
    );
  });
}
