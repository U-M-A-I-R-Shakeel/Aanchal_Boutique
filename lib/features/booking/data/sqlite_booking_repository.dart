import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/database/db_codec.dart';
import '../../home/data/room_status_sync.dart';
import '../domain/booking_exception.dart';
import '../domain/booking_repository.dart';
import '../domain/booking_rules.dart';
import '../domain/models/booking.dart';

class SqliteBookingRepository implements BookingRepository {
  SqliteBookingRepository(this._db);

  final Database _db;

  static const _table = 'bookings';

  @override
  Future<List<Booking>> getBookings() async {
    final rows = await _db.query(_table, orderBy: 'date, start_time, id');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Booking> create({
    required String roomId,
    required DateTime start,
    required String customerName,
    required DateTime now,
  }) async {
    try {
      return await _db.transaction((txn) async {
        final room = await txn.query(
          'rooms',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [roomId],
        );
        if (room.isEmpty || room.single['status'] == 'busy') {
          throw const BookingException(AppStrings.slotTaken);
        }

        final booking = Booking(
          id: 0,
          roomId: roomId,
          start: start,
          customerName: customerName,
          createdAt: now,
        );
        final row = _toRow(booking)..remove('id');
        final id = await txn.insert(_table, row);

        await syncRoomStatuses(
          txn,
          activeAfter: now.subtract(BookingRules.slotLength),
          roomId: roomId,
        );
        return _fromRow({...row, 'id': id});
      });
    } on DatabaseException catch (e) {
      // Unique index: another confirmed booking already holds this slot.
      if (e.isUniqueConstraintError()) {
        throw const BookingException(AppStrings.slotTaken);
      }
      rethrow;
    }
  }

  @override
  Future<Booking> cancel(Booking booking, {required DateTime now}) {
    return _db.transaction((txn) async {
      final updated = await txn.update(
        _table,
        {'status': BookingStatus.cancelled.name, 'cancelled_at': _ts(now)},
        where: 'id = ? AND status = ?',
        whereArgs: [booking.id, BookingStatus.confirmed.name],
      );
      if (updated == 0) {
        throw const BookingException(AppStrings.alreadyCancelled);
      }
      await syncRoomStatuses(
        txn,
        activeAfter: now.subtract(BookingRules.slotLength),
        roomId: booking.roomId,
      );
      final rows = await txn.query(
        _table,
        where: 'id = ?',
        whereArgs: [booking.id],
      );
      return _fromRow(rows.single);
    });
  }

  static String _ts(DateTime d) => d.toIso8601String();

  static Map<String, Object?> _toRow(Booking b) => {
    'id': b.id,
    'room_id': b.roomId,
    'date': DbCodec.date(b.start),
    'start_time': DbCodec.time(b.start),
    'customer_name': b.customerName,
    'status': b.status.name,
    'created_at': _ts(b.createdAt),
    'cancelled_at': b.cancelledAt == null ? null : _ts(b.cancelledAt!),
  };

  static Booking _fromRow(Map<String, Object?> r) => Booking(
    id: r['id']! as int,
    roomId: r['room_id']! as String,
    start: DbCodec.parse(r['date']! as String, r['start_time']! as String),
    customerName: r['customer_name']! as String,
    status: BookingStatus.values.byName(r['status']! as String),
    createdAt: DateTime.parse(r['created_at']! as String),
    cancelledAt: r['cancelled_at'] == null
        ? null
        : DateTime.parse(r['cancelled_at']! as String),
  );
}
