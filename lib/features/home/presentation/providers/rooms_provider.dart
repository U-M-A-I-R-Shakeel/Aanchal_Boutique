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
}

final roomsProvider = NotifierProvider<RoomsNotifier, List<Room>>(
  RoomsNotifier.new,
);
