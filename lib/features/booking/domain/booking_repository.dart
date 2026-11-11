import 'models/booking.dart';

abstract interface class BookingRepository {
  /// Every booking, confirmed and cancelled, oldest slot first.
  Future<List<Booking>> getBookings();

  /// Confirmed bookings on [date], earliest slot first.
  Future<List<Booking>> getBookingsForDate(DateTime date);

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

  /// Deletes [booking] and frees the room if it has no other upcoming
  /// bookings.
  ///
  /// Throws `BookingException` if it no longer exists.
  Future<void> cancel(Booking booking, {required DateTime now});
}
