import '../domain/models/booking.dart';

/// Source of existing bookings.
///
/// Seeded with a few static bookings relative to [today] so the slot grid
/// shows some taken slots. Replace with an API/Firebase source later.
class BookingRepository {
  const BookingRepository();

  List<Booking> getBookings({required DateTime today}) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) =>
        DateTime(today.year, today.month, today.day + dayOffset, hour, minute);

    final seed = <(String, DateTime)>[
      ('room-1', at(0, 11)),
      ('room-1', at(0, 14, 30)),
      ('room-1', at(1, 10)),
      ('room-3', at(0, 12)),
      ('room-3', at(0, 12, 30)),
      ('room-3', at(2, 16)),
    ];

    return [
      for (final (roomId, start) in seed)
        Booking(
          id: 'seed-$roomId-${start.toIso8601String()}',
          roomId: roomId,
          start: start,
        ),
    ];
  }
}
