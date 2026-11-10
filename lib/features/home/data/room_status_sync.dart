import 'package:sqflite/sqflite.dart';

import '../../../core/database/db_codec.dart';

/// Recomputes the stored status of rooms that aren't busy: `booked` if the
/// room has a confirmed booking whose slot hasn't ended yet, else `available`.
///
/// A slot is still active if it started after [activeAfter]
/// (i.e. `now - slotLength`).
Future<void> syncRoomStatuses(
  DatabaseExecutor db, {
  required DateTime activeAfter,
  String? roomId,
}) {
  return db.rawUpdate(
    '''
    UPDATE rooms SET status = CASE WHEN EXISTS (
        SELECT 1 FROM bookings b
        WHERE b.room_id = rooms.id
          AND b.status = 'confirmed'
          AND (b.date || ' ' || b.start_time) > ?
      ) THEN 'booked' ELSE 'available' END
    WHERE status != 'busy' ${roomId == null ? '' : 'AND id = ?'}
    ''',
    [DbCodec.dateTime(activeAfter), if (roomId != null) roomId],
  );
}
