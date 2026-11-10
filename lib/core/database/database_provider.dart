import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// The opened app database. Overridden in `main()` once it has been opened.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError(
    'databaseProvider must be overridden with an opened Database',
  ),
);
