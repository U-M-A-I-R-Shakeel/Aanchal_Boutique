import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/utils/clock.dart';
import '../../data/sqlite_room_repository.dart';
import '../../domain/models/room.dart';
import '../../domain/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => SqliteRoomRepository(ref.watch(databaseProvider)),
);

/// Rooms shown on the Home screen, loaded from the database.
///
/// Invalidate it after a write that can change a room's status.
class RoomsNotifier extends AsyncNotifier<List<Room>> {
  @override
  Future<List<Room>> build() => ref
      .watch(roomRepositoryProvider)
      .getRooms(now: ref.read(clockProvider)());

  Room? byId(String roomId) =>
      state.value?.where((r) => r.id == roomId).firstOrNull;
}

final roomsProvider = AsyncNotifierProvider<RoomsNotifier, List<Room>>(
  RoomsNotifier.new,
);
