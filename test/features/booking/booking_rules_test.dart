import 'package:aanchal_boutique/features/booking/domain/booking_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 10, 13, 15);

  test('bookable dates are today plus the next 6 days', () {
    final dates = BookingRules.bookableDates(now);
    expect(dates, hasLength(7));
    expect(dates.first, DateTime(2026, 11, 10));
    expect(dates.last, DateTime(2026, 11, 16));
  });

  test('bookable dates roll over month end', () {
    final dates = BookingRules.bookableDates(DateTime(2026, 11, 28));
    expect(dates.last, DateTime(2026, 12, 4));
  });

  test('slots run 10:00 AM to 5:30 PM in 30-minute steps', () {
    final slots = BookingRules.slotsFor(DateTime(2026, 11, 11));
    expect(slots, hasLength(16));
    expect(slots.first, DateTime(2026, 11, 11, 10));
    expect(slots[1], DateTime(2026, 11, 11, 10, 30));
    expect(slots.last, DateTime(2026, 11, 11, 17, 30));
  });

  test('isPast and isValidSlot', () {
    expect(BookingRules.isPast(DateTime(2026, 11, 10, 13), now), isTrue);
    expect(BookingRules.isPast(DateTime(2026, 11, 10, 13, 30), now), isFalse);

    expect(
      BookingRules.isValidSlot(DateTime(2026, 11, 12, 15, 30), now),
      isTrue,
    );
    expect(
      BookingRules.isValidSlot(DateTime(2026, 11, 12, 15, 15), now),
      isFalse,
    );
    expect(BookingRules.isValidSlot(DateTime(2026, 11, 12, 18), now), isFalse);
    expect(BookingRules.isValidSlot(DateTime(2026, 11, 17, 10), now), isFalse);
  });
}
