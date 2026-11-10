import 'models/booking.dart';

abstract interface class BookingRepository {
  /// Every booking, confirmed and cancelled, oldest slot first.
  Future<List<Booking>> getBookings();

  /// Saves a confirmed booking and marks the room as booked.
  ///
  /// Throws `BookingException` if the room is busy or the slot already has a
  /// confirmed booking.
  Future<Booking> create({
    required String roomId,
    required DateTime start,
    required String customerName,
    required DateTime now,
  });

  /// Marks [booking] as cancelled (the row is kept) and frees the room if it
  /// has no other upcoming bookings. Returns the updated booking.
  ///
  /// Throws `BookingException` if it was already cancelled.
  Future<Booking> cancel(Booking booking, {required DateTime now});
}
