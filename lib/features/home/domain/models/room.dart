import 'package:flutter/foundation.dart';

enum RoomStatus { available, busy, booked }

@immutable
class Room {
  const Room({required this.id, required this.name, required this.status});

  final String id;
  final String name;
  final RoomStatus status;

  bool get isAvailable => status == RoomStatus.available;

  /// A room can take new bookings unless it is currently busy. Rooms the
  /// customer has already booked stay bookable for other time slots.
  bool get canBook => status != RoomStatus.busy;

  Room copyWith({String? id, String? name, RoomStatus? status}) => Room(
    id: id ?? this.id,
    name: name ?? this.name,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is Room &&
      other.id == id &&
      other.name == name &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, name, status);

  @override
  String toString() => 'Room(id: $id, name: $name, status: $status)';
}
