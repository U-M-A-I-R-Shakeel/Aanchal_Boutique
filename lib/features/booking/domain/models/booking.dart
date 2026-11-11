import 'package:flutter/foundation.dart';

import '../booking_rules.dart';

enum BookingStatus { confirmed, cancelled }

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.roomId,
    required this.start,
    required this.customerName,
    required this.createdAt,
    this.status = BookingStatus.confirmed,
    this.cancelledAt,
  });

  /// Database row id.
  final int id;
  final String roomId;

  /// Date and start time of the 30-minute slot, in local time.
  final DateTime start;
  final String customerName;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  DateTime get date => DateTime(start.year, start.month, start.day);
  DateTime get end => start.add(BookingRules.slotLength);
  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Confirmed and the slot hasn't finished yet.
  bool isUpcoming(DateTime now) => isConfirmed && end.isAfter(now);

  @override
  bool operator ==(Object other) =>
      other is Booking &&
      other.id == id &&
      other.roomId == roomId &&
      other.start == start &&
      other.customerName == customerName &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.cancelledAt == cancelledAt;

  @override
  int get hashCode => Object.hash(
    id,
    roomId,
    start,
    customerName,
    status,
    createdAt,
    cancelledAt,
  );

  @override
  String toString() =>
      'Booking(#$id, $roomId, $start, $customerName, '
      '${status.name})';
}
