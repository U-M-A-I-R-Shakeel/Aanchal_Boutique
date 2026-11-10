import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/room_repository.dart';
import '../../domain/models/room.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => const RoomRepository(),
);

/// Holds the list of fitting rooms shown on the Home screen.
class RoomsNotifier extends Notifier<List<Room>> {
  @override
  List<Room> build() => ref.watch(roomRepositoryProvider).getRooms();

  Room? byId(String roomId) {
    for (final room in state) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  void updateStatus(String roomId, RoomStatus status) {
    state = [
      for (final room in state)
        room.id == roomId ? room.copyWith(status: status) : room,
    ];
  }
}

final roomsProvider = NotifierProvider<RoomsNotifier, List<Room>>(
  RoomsNotifier.new,
);
