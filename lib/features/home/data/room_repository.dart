import '../domain/models/room.dart';

/// Source of fitting-room data.
///
/// Currently backed by a static list; swap this for an API/Firebase
/// implementation later without touching the UI.
class RoomRepository {
  const RoomRepository();

  List<Room> getRooms() => const [
        Room(id: 'room-1', name: 'Room 1', status: RoomStatus.available),
        Room(id: 'room-2', name: 'Room 2', status: RoomStatus.busy),
        Room(id: 'room-3', name: 'Room 3', status: RoomStatus.available),
      ];
}
