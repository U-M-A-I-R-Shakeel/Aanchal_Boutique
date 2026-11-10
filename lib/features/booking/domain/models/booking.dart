import 'package:flutter/foundation.dart';

@immutable
class Booking {
  const Booking({required this.id, required this.roomId, required this.start});

  final String id;
  final String roomId;

  /// Start of the 30-minute slot, in local time.
  final DateTime start;

  @override
  bool operator ==(Object other) =>
      other is Booking &&
      other.id == id &&
      other.roomId == roomId &&
      other.start == start;

  @override
  int get hashCode => Object.hash(id, roomId, start);

  @override
  String toString() => 'Booking(id: $id, roomId: $roomId, start: $start)';
}
