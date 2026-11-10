import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/utils/clock.dart';
import '../../../home/presentation/providers/rooms_provider.dart';
import '../../data/sqlite_booking_repository.dart';
import '../../domain/booking_exception.dart';
import '../../domain/booking_repository.dart';
import '../../domain/booking_rules.dart';
import '../../domain/models/booking.dart';

export '../../domain/booking_exception.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => SqliteBookingRepository(ref.watch(databaseProvider)),
);

/// All bookings, loaded from the database. Writes go to the database first;
/// in-memory state is only updated once the write has succeeded.
class BookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() =>
      ref.watch(bookingRepositoryProvider).getBookings();

  List<Booking> get _current => state.value ?? const [];

  bool isSlotTaken(String roomId, DateTime start) => _current.any(
    (b) => b.isConfirmed && b.roomId == roomId && b.start == start,
  );

  /// Validates and saves a booking, then refreshes room statuses.
  ///
  /// Throws [BookingException] with a user-facing message if it can't be made.
  Future<Booking> book({
    required String roomId,
    required DateTime start,
    required String customerName,
  }) async {
    final now = ref.read(clockProvider)();
    final name = customerName.trim();
    final rooms = await ref.read(roomsProvider.future);
    final room = rooms.where((r) => r.id == roomId).firstOrNull;
    await future; // make sure existing bookings are loaded for the check below

    if (name.isEmpty) throw const BookingException(AppStrings.nameRequired);
    if (room == null || !room.canBook) {
      throw BookingException(AppStrings.roomIsBusy(room?.name ?? 'This room'));
    }
    if (!BookingRules.isValidSlot(start, now) ||
        BookingRules.isPast(start, now) ||
        isSlotTaken(roomId, start)) {
      throw const BookingException(AppStrings.slotTaken);
    }

    final booking = await ref
        .read(bookingRepositoryProvider)
        .create(roomId: roomId, start: start, customerName: name, now: now);
    state = AsyncData([..._current, booking]);
    ref.invalidate(roomsProvider);
    return booking;
  }

  Future<void> cancel(Booking booking) async {
    final cancelled = await ref
        .read(bookingRepositoryProvider)
        .cancel(booking, now: ref.read(clockProvider)());
    state = AsyncData([
      for (final b in _current) b.id == booking.id ? cancelled : b,
    ]);
    ref.invalidate(roomsProvider);
  }
}

final bookingsProvider = AsyncNotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

/// Slot start times with a confirmed booking for a room.
final bookedSlotsProvider = Provider.family<Set<DateTime>, String>(
  (ref, roomId) => {
    for (final b in ref.watch(bookingsProvider).value ?? const <Booking>[])
      if (b.isConfirmed && b.roomId == roomId) b.start,
  },
);
