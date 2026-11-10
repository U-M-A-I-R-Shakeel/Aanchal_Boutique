/// Converts local date/times to and from the text columns in SQLite.
abstract final class DbCodec {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `yyyy-MM-dd`
  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// `HH:mm`
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// `yyyy-MM-dd HH:mm`, which sorts and compares correctly as text.
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  static DateTime parse(String date, String time) =>
      DateTime.parse('${date}T$time:00');
}
