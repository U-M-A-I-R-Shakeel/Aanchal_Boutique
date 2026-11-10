import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now". Override in tests to get deterministic dates and times.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

extension DateOnly on DateTime {
  /// Midnight (local time) of this date.
  DateTime get dateOnly => DateTime(year, month, day);
}
