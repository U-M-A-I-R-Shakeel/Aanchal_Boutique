import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the app's SQLite database and owns its schema.
abstract final class AppDatabase {
  static const fileName = 'aanchal_boutique.db';
  static const version = 1;

  static Future<Database> open({String? path, DatabaseFactory? factory}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      ),
    );
  }

  /// Runs once, inside a transaction, when the database file is created.
  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE rooms (
          id         TEXT PRIMARY KEY,
          name       TEXT NOT NULL,
          status     TEXT NOT NULL
                     CHECK (status IN ('available', 'busy', 'booked')),
          sort_order INTEGER NOT NULL
        )''')
      ..execute('''
        CREATE TABLE bookings (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          room_id       TEXT NOT NULL REFERENCES rooms (id),
          date          TEXT NOT NULL, -- yyyy-MM-dd (local)
          start_time    TEXT NOT NULL, -- HH:mm (local)
          customer_name TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'confirmed'
                        CHECK (status IN ('confirmed', 'cancelled')),
          created_at    TEXT NOT NULL,
          cancelled_at  TEXT
        )''')
      // A slot can hold only one confirmed booking per room. Cancelled rows
      // are kept for history and don't block the slot.
      ..execute('''
        CREATE UNIQUE INDEX bookings_one_active_per_slot
        ON bookings (room_id, date, start_time)
        WHERE status = 'confirmed' ''');

    const seedRooms = [
      ('room-1', 'Room 1', 'available'),
      ('room-2', 'Room 2', 'busy'),
      ('room-3', 'Room 3', 'available'),
    ];
    for (final (i, (id, name, status)) in seedRooms.indexed) {
      batch.insert('rooms', {
        'id': id,
        'name': name,
        'status': status,
        'sort_order': i,
      });
    }
    await batch.commit(noResult: true);
  }
}
