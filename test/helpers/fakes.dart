import 'package:aanchal_boutique/core/constants/app_strings.dart';
import 'package:aanchal_boutique/features/booking/domain/booking_exception.dart';
import 'package:aanchal_boutique/features/booking/domain/booking_repository.dart';
import 'package:aanchal_boutique/features/booking/domain/models/booking.dart';
import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:aanchal_boutique/features/home/domain/room_repository.dart';

/// In-memory stand-in for the SQLite database, for widget tests.
/// Mirrors the SQLite repositories' rules.
class FakeStore {
  FakeStore({List<Room>? rooms, List<Booking>? bookings})
    : rooms =
          rooms ??
          const [
            Room(id: 'room-1', name: 'Room 1', status: RoomStatus.available),
            Room(id: 'room-2', name: 'Room 2', status: RoomStatus.busy),
            Room(id: 'room-3', name: 'Room 3', status: RoomStatus.available),
          ],
      bookings = [...?bookings];

  List<Room> rooms;
  final List<Booking> bookings;
  int _nextId = 1000;

  void sync(DateTime now, {String? roomId}) {
    rooms = [
      for (final r in rooms)
        if (r.status == RoomStatus.busy || (roomId != null && r.id != roomId))
          r
        else
          r.copyWith(
            status: bookings.any((b) => b.roomId == r.id && b.isUpcoming(now))
                ? RoomStatus.booked
                : RoomStatus.available,
          ),
    ];
  }
}

class FakeRoomRepository implements RoomRepository {
  FakeRoomRepository(this.store);
  final FakeStore store;

  @override
  Future<List<Room>> getRooms({required DateTime now}) async {
    store.sync(now);
    return List.of(store.rooms);
  }
}

class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository(this.store);
  final FakeStore store;

  @override
  Future<List<Booking>> getBookings() async => List.of(store.bookings);

  @override
  Future<Booking> create({
    required String roomId,
    required DateTime start,
    required String customerName,
    required DateTime now,
  }) async {
    final room = store.rooms.where((r) => r.id == roomId).firstOrNull;
    final taken = store.bookings.any(
      (b) => b.isConfirmed && b.roomId == roomId && b.start == start,
    );
    if (room == null || room.status == RoomStatus.busy || taken) {
      throw const BookingException(AppStrings.slotTaken);
    }
    final booking = Booking(
      id: store._nextId++,
      roomId: roomId,
      start: start,
      customerName: customerName,
      createdAt: now,
    );
    store.bookings.add(booking);
    store.sync(now, roomId: roomId);
    return booking;
  }

  @override
  Future<Booking> cancel(Booking booking, {required DateTime now}) async {
    final i = store.bookings.indexWhere((b) => b.id == booking.id);
    if (i < 0 || !store.bookings[i].isConfirmed) {
      throw const BookingException(AppStrings.alreadyCancelled);
    }
    final cancelled = store.bookings[i].cancel(now);
    store.bookings[i] = cancelled;
    store.sync(now, roomId: booking.roomId);
    return cancelled;
  }
}

Booking fakeBooking(
  int id,
  String roomId,
  DateTime start, {
  String name = 'Sana',
  BookingStatus status = BookingStatus.confirmed,
}) => Booking(
  id: id,
  roomId: roomId,
  start: start,
  customerName: name,
  createdAt: start.subtract(const Duration(days: 1)),
  status: status,
);
