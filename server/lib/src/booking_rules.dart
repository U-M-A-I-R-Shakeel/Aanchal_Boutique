/// Opening hours and slot rules. Same values as the app's
/// `lib/features/booking/domain/booking_rules.dart`; change both together.
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

  /// Slot start times for [date]: 10:00 up to 17:30.
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

  static bool isValidSlot(DateTime start, DateTime now) {
    final day = DateTime(start.year, start.month, start.day);
    return bookableDates(now).contains(day) && slotsFor(day).contains(start);
  }
}

/// `yyyy-MM-dd` and `HH:mm` text, as stored in the database and used in JSON.
abstract final class DateText {
  static String _two(int n) => n.toString().padLeft(2, '0');
  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _timeRe = RegExp(r'^\d{2}:\d{2}$');

  /// Parses `yyyy-MM-dd`, or returns null if it isn't a real date.
  static DateTime? parseDate(String? s) {
    if (s == null || !_dateRe.hasMatch(s)) return null;
    final d = DateTime.tryParse(s);
    return d != null && date(d) == s ? d : null;
  }

  /// Combines a date with `HH:mm`, or returns null if the time is invalid.
  static DateTime? parseTime(DateTime date, String? s) {
    if (s == null || !_timeRe.hasMatch(s)) return null;
    final h = int.parse(s.substring(0, 2)), m = int.parse(s.substring(3));
    if (h > 23 || m > 59) return null;
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
