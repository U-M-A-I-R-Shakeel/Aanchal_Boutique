import 'package:sqlite3/sqlite3.dart';

/// Opens the API database at [path] (or in memory) and creates the schema
/// and the three rooms on first use. Same tables as the app.
Database openApiDatabase({String? path}) {
  final db = path == null ? sqlite3.openInMemory() : sqlite3.open(path);
  db.execute('PRAGMA foreign_keys = ON');
  db.execute('''
    CREATE TABLE IF NOT EXISTS rooms (
      id         TEXT PRIMARY KEY,
      name       TEXT NOT NULL,
      status     TEXT NOT NULL CHECK (status IN ('available', 'busy', 'booked')),
      sort_order INTEGER NOT NULL
    )''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS bookings (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      room_id       TEXT NOT NULL REFERENCES rooms (id),
      date          TEXT NOT NULL,
      start_time    TEXT NOT NULL,
      customer_name TEXT NOT NULL,
      created_at    TEXT NOT NULL
    )''');
  db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS bookings_one_per_slot
    ON bookings (room_id, date, start_time)''');
  final seeded = db.select('SELECT COUNT(*) AS n FROM rooms').first['n'] as int;
  if (seeded == 0) {
    final insert = db.prepare(
      'INSERT INTO rooms (id, name, status, sort_order) VALUES (?, ?, ?, ?)',
    );
    for (final (i, (id, name, status)) in const [
      ('room-1', 'Room 1', 'available'),
      ('room-2', 'Room 2', 'busy'),
      ('room-3', 'Room 3', 'available'),
    ].indexed) {
      insert.execute([id, name, status, i]);
    }
    insert.dispose();
  }
  return db;
}
