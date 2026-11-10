import 'package:sqflite/sqflite.dart';

import '../../booking/domain/booking_rules.dart';
import '../domain/models/room.dart';
import '../domain/room_repository.dart';
import 'room_status_sync.dart';

class SqliteRoomRepository implements RoomRepository {
  SqliteRoomRepository(this._db);

  final Database _db;

  @override
  Future<List<Room>> getRooms({required DateTime now}) {
    return _db.transaction((txn) async {
      await syncRoomStatuses(
        txn,
        activeAfter: now.subtract(BookingRules.slotLength),
      );
      final rows = await txn.query('rooms', orderBy: 'sort_order');
      return [
        for (final row in rows)
          Room(
            id: row['id']! as String,
            name: row['name']! as String,
            status: RoomStatus.values.byName(row['status']! as String),
          ),
      ];
    });
  }
}
