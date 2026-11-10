/// Opening hours and slot rules for fitting-room bookings.
abstract final class BookingRules {
  static const openingHour = 10; // 10:00 AM
  static const closingHour = 18; // 6:00 PM
  static const slotLength = Duration(minutes: 30);
  static const bookingWindowDays = 7;

  /// Today plus the following six days, each at midnight.
  static List<DateTime> bookableDates(DateTime now) => List.generate(
    bookingWindowDays,
    (i) => DateTime(now.year, now.month, now.day + i),
  );

  /// Slot start times for [date]: 10:00 AM up to 5:30 PM, so the last slot
  /// ends at closing time (6:00 PM).
  static List<DateTime> slotsFor(DateTime date) {
    final close = DateTime(date.year, date.month, date.day, closingHour);
    final slots = <DateTime>[];
    var start = DateTime(date.year, date.month, date.day, openingHour);
    while (!start.add(slotLength).isAfter(close)) {
      slots.add(start);
      start = start.add(slotLength);
    }
    return slots;
  }

  static bool isPast(DateTime slotStart, DateTime now) =>
      !slotStart.isAfter(now);

  /// Whether [start] is a real slot (on the grid, within the 7-day window).
  static bool isValidSlot(DateTime start, DateTime now) {
    final dates = bookableDates(now);
    final day = DateTime(start.year, start.month, start.day);
    return dates.contains(day) && slotsFor(day).contains(start);
  }
}
