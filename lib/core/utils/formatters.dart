import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _weekday = DateFormat.E(); // Tue
  static final _day = DateFormat.d(); // 11
  static final _month = DateFormat.MMM(); // Nov
  static final _fullDate = DateFormat('EEE, d MMM'); // Tue, 11 Nov
  static final _time = DateFormat.jm(); // 2:30 PM

  static String weekday(DateTime d) => _weekday.format(d);
  static String day(DateTime d) => _day.format(d);
  static String month(DateTime d) => _month.format(d);
  static String fullDate(DateTime d) => _fullDate.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateAndTime(DateTime d) => '${fullDate(d)} at ${time(d)}';
}
