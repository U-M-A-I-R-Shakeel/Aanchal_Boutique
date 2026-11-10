import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/clock.dart';
import '../../../home/domain/models/room.dart';
import '../../../home/presentation/providers/rooms_provider.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_rules.dart';
import '../../domain/models/booking.dart';

class BookingException implements Exception {
  const BookingException(this.message);
  final String message;

  @override
  String toString() => 'BookingException: $message';
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => const BookingRepository(),
);

/// All bookings across rooms.
class BookingsNotifier extends Notifier<List<Booking>> {
  @override
  List<Booking> build() {
    final today = ref.read(clockProvider)().dateOnly;
    return ref.read(bookingRepositoryProvider).getBookings(today: today);
  }

  bool isSlotTaken(String roomId, DateTime start) =>
      state.any((b) => b.roomId == roomId && b.start == start);

  /// Books [start] for [roomId] and marks the room as booked.
  ///
  /// Throws [BookingException] if the room is busy, or the slot is already
  /// booked, in the past, or not a valid slot.
  Booking book({required String roomId, required DateTime start}) {
    final now = ref.read(clockProvider)();
    final room = ref.read(roomsProvider.notifier).byId(roomId);

    if (room == null || !room.canBook) {
      throw BookingException(AppStrings.roomIsBusy(room?.name ?? 'Room'));
    }
    if (!BookingRules.isValidSlot(start, now) ||
        BookingRules.isPast(start, now) ||
        isSlotTaken(roomId, start)) {
      throw const BookingException(AppStrings.slotTaken);
    }

    final booking = Booking(
      id: '$roomId-${start.toIso8601String()}',
      roomId: roomId,
      start: start,
    );
    state = [...state, booking];
    ref.read(roomsProvider.notifier).updateStatus(roomId, RoomStatus.booked);
    return booking;
  }
}

final bookingsProvider = NotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

/// Slot start times already booked for a room.
final bookedSlotsProvider = Provider.family<Set<DateTime>, String>(
  (ref, roomId) => {
    for (final b in ref.watch(bookingsProvider))
      if (b.roomId == roomId) b.start,
  },
);
