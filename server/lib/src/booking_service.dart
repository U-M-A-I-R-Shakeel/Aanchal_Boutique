import 'package:sqlite3/sqlite3.dart';

import 'booking_rules.dart';

/// An error to send back as JSON: `{"error": {"code": ..., "message": ...}}`.
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
}

/// Booking logic on top of the database. Every method returns plain JSON
/// maps, ready to encode.
class BookingService {
  BookingService(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  // Rooms ------------------------------------------------------------------

  List<Map<String, Object?>> rooms() {
    _syncRoomStatuses();
    return [
      for (final r in _db.select('SELECT * FROM rooms ORDER BY sort_order'))
        {'id': r['id'], 'name': r['name'], 'status': r['status']},
    ];
  }

  Map<String, Object?> _room(String id) {
    _syncRoomStatuses();
    final rows = _db.select('SELECT * FROM rooms WHERE id = ?', [id]);
    if (rows.isEmpty) {
      throw ApiException(404, 'room_not_found', 'No room with id "$id".');
    }
    final r = rows.first;
    return {'id': r['id'], 'name': r['name'], 'status': r['status']};
  }

  /// Every slot on [dateText] for a room: `available`, `booked` or `past`.
  Map<String, Object?> slots(String roomId, String? dateText) {
    final room = _room(roomId);
    final date = _requireDate(dateText);
    final now = _now();
    final taken = {
      for (final r in _db.select(
        'SELECT start_time FROM bookings WHERE room_id = ? AND date = ?',
        [roomId, DateText.date(date)],
      ))
        r['start_time'] as String,
    };
    return {
      'room': room,
      'date': DateText.date(date),
      'slots': [
        for (final s in BookingRules.slotsFor(date))
          {
            'time': DateText.time(s),
            'status': taken.contains(DateText.time(s))
                ? 'booked'
                : BookingRules.isPast(s, now)
                ? 'past'
                : 'available',
          },
      ],
    };
  }

  // Bookings ---------------------------------------------------------------

  /// All bookings, or one day's when [dateText] is given, earliest first.
  List<Map<String, Object?>> bookings({String? dateText}) {
    final date = dateText == null ? null : _requireDate(dateText);
    final rows = _db.select(
      '''SELECT b.*, r.name AS room_name FROM bookings b
         JOIN rooms r ON r.id = b.room_id
         ${date == null ? '' : 'WHERE b.date = ?'}
         ORDER BY b.date, b.start_time, b.id''',
      [if (date != null) DateText.date(date)],
    );
    return rows.map(_bookingJson).toList();
  }

  Map<String, Object?> booking(int id) {
    final rows = _db.select(
      '''SELECT b.*, r.name AS room_name FROM bookings b
         JOIN rooms r ON r.id = b.room_id WHERE b.id = ?''',
      [id],
    );
    if (rows.isEmpty) {
      throw ApiException(404, 'booking_not_found', 'No booking with id $id.');
    }
    return _bookingJson(rows.first);
  }

  /// Validates and saves a booking; marks the room as booked.
  Map<String, Object?> create(Map<String, Object?> body) {
    String? text(String key) {
      final v = body[key];
      if (v != null && v is! String) {
        throw ApiException(400, 'invalid_request', '"$key" must be a string.');
      }
      return (v as String?)?.trim();
    }

    final roomId = text('roomId');
    final name = text('customerName');
    if (roomId == null || roomId.isEmpty) {
      throw const ApiException(400, 'invalid_request', '"roomId" is required.');
    }
    if (name == null || name.isEmpty) {
      throw const ApiException(
        400,
        'invalid_request',
        '"customerName" is required.',
      );
    }
    if (name.length > 80) {
      throw const ApiException(
        400,
        'invalid_request',
        '"customerName" must be at most 80 characters.',
      );
    }
    final date = _requireDate(text('date'));
    final start = DateText.parseTime(date, text('time'));
    if (start == null) {
      throw const ApiException(
        400,
        'invalid_request',
        '"time" must be HH:mm, e.g. "10:30".',
      );
    }

    final now = _now();
    final room = _room(roomId);
    if (room['status'] == 'busy') {
      throw ApiException(
        409,
        'room_busy',
        '${room['name']} is busy right now.',
      );
    }
    if (!BookingRules.isValidSlot(start, now)) {
      throw const ApiException(
        400,
        'invalid_slot',
        'Slots are every 30 minutes from 10:00 to 17:30, '
            'from today up to 6 days ahead.',
      );
    }
    if (BookingRules.isPast(start, now)) {
      throw const ApiException(400, 'slot_in_past', 'That slot has started.');
    }

    try {
      _db.execute('BEGIN');
      _db.execute(
        '''INSERT INTO bookings (room_id, date, start_time, customer_name, created_at)
           VALUES (?, ?, ?, ?, ?)''',
        [
          roomId,
          DateText.date(start),
          DateText.time(start),
          name,
          now.toIso8601String(),
        ],
      );
      final id = _db.lastInsertRowId;
      _syncRoomStatuses(roomId: roomId);
      _db.execute('COMMIT');
      return booking(id);
    } on SqliteException catch (e) {
      _db.execute('ROLLBACK');
      if (e.extendedResultCode == 2067) {
        // SQLITE_CONSTRAINT_UNIQUE
        throw const ApiException(
          409,
          'slot_taken',
          'That slot is already booked.',
        );
      }
      rethrow;
    }
  }

  /// Deletes a booking and frees the room if it has no other upcoming one.
  void cancel(int id) {
    final existing = booking(id); // 404 if missing
    _db.execute('BEGIN');
    _db.execute('DELETE FROM bookings WHERE id = ?', [id]);
    _syncRoomStatuses(roomId: existing['roomId'] as String);
    _db.execute('COMMIT');
  }

  // Helpers ----------------------------------------------------------------

  DateTime _requireDate(String? s) {
    final d = DateText.parseDate(s);
    if (d == null) {
      throw const ApiException(
        400,
        'invalid_request',
        '"date" must be a real date in yyyy-MM-dd format.',
      );
    }
    return d;
  }

  /// `booked` while a room has a booking that hasn't ended, else `available`.
  /// Busy rooms are left alone.
  void _syncRoomStatuses({String? roomId}) {
    final activeAfter = _now().subtract(BookingRules.slotLength);
    _db.execute(
      '''UPDATE rooms SET status = CASE WHEN EXISTS (
           SELECT 1 FROM bookings b WHERE b.room_id = rooms.id
             AND (b.date || ' ' || b.start_time) > ?
         ) THEN 'booked' ELSE 'available' END
         WHERE status != 'busy' ${roomId == null ? '' : 'AND id = ?'}''',
      [DateText.dateTime(activeAfter), ?roomId],
    );
  }

  static Map<String, Object?> _bookingJson(Row r) => {
    'id': r['id'],
    'roomId': r['room_id'],
    'roomName': r['room_name'],
    'date': r['date'],
    'time': r['start_time'],
    'customerName': r['customer_name'],
    'createdAt': r['created_at'],
  };
}
