import 'package:aanchal_boutique/features/booking/domain/models/booking.dart';
import 'package:aanchal_boutique/features/booking/presentation/screens/bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('lists upcoming and past bookings; cancel frees the room', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      store: FakeStore(
        bookings: [
          fakeBooking(1, 'room-1', DateTime(2026, 11, 9, 14), name: 'Zara'),
          fakeBooking(2, 'room-1', DateTime(2026, 11, 11, 10), name: 'Sana'),
          fakeBooking(
            3,
            'room-3',
            DateTime(2026, 11, 8, 12),
            name: 'Mehr',
            status: BookingStatus.cancelled,
          ),
        ],
      ),
    );
    expect(find.text('Booked'), findsOneWidget); // Room 1

    await tester.tap(find.byTooltip('Bookings'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingsScreen), findsOneWidget);
    expect(find.text('Upcoming (1)'), findsOneWidget);
    expect(find.text('Past & cancelled (2)'), findsOneWidget);
    expect(find.text('Room 1 · Sana'), findsOneWidget);
    expect(find.text('Room 1 · Zara'), findsOneWidget); // yesterday's booking
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-2')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this booking?'), findsOneWidget);
    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.text('Upcoming (0)'), findsOneWidget);
    expect(find.text('Past & cancelled (3)'), findsOneWidget);
    expect(store.bookings.firstWhere((b) => b.id == 2).isConfirmed, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Booked'), findsNothing);
    expect(find.text('Available'), findsNWidgets(2));
  });

  testWidgets('keep booking leaves it untouched', (tester) async {
    final store = await pumpApp(
      tester,
      store: FakeStore(
        bookings: [fakeBooking(2, 'room-1', DateTime(2026, 11, 11, 10))],
      ),
    );
    await tester.tap(find.byTooltip('Bookings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cancel-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep booking'));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming (1)'), findsOneWidget);
    expect(store.bookings.single.isConfirmed, isTrue);
  });
}
