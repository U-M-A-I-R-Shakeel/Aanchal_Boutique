import 'models/room.dart';

abstract interface class RoomRepository {
  /// All rooms in display order, with "Booked" statuses brought up to date
  /// for [now] (a room whose bookings have all ended goes back to Available).
  Future<List<Room>> getRooms({required DateTime now});
}
