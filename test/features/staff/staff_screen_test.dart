import 'package:aanchal_boutique/features/booking/presentation/screens/booking_screen.dart';
import 'package:aanchal_boutique/features/staff/presentation/screens/staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  FakeStore storeWithSchedule() => FakeStore(
    bookings: [
      fakeBooking(1, 'room-1', DateTime(2026, 11, 10, 15), name: 'Late'),
      fakeBooking(2, 'room-3', DateTime(2026, 11, 10, 10, 30), name: 'Early'),
      fakeBooking(3, 'room-1', DateTime(2026, 11, 11, 12), name: 'Tomorrow'),
    ],
  );

  Future<void> openStaff(WidgetTester tester) async {
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
  }

  Finder cancel(int id) => find.byKey(ValueKey('staff-cancel-$id'));

  testWidgets('bottom navigation switches between Home and Staff', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Fitting Rooms'), findsOneWidget);
    expect(find.text('Daily Schedule'), findsNothing);

    await openStaff(tester);
    expect(find.byType(StaffScreen), findsOneWidget);
    expect(find.text('Daily Schedule'), findsOneWidget);
    expect(find.text('Fitting Rooms'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Fitting Rooms'), findsOneWidget);
  });

  testWidgets('shows only the selected day, sorted, with name, room, time', (
    tester,
  ) async {
    await pumpApp(tester, store: storeWithSchedule());
    await openStaff(tester);

    expect(find.text('Early'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget);
    expect(find.text('Tomorrow'), findsNothing);
    expect(find.text('Room 3'), findsOneWidget);
    expect(find.textContaining('10:30'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Early')).dy,
      lessThan(tester.getTopLeft(find.text('Late')).dy),
    );
    expect(find.text('Cancel'), findsNWidgets(2));
  });

  testWidgets('arrows and date picker switch days', (tester) async {
    await pumpApp(tester, store: storeWithSchedule());
    await openStaff(tester);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Early'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('staff-pick-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings on this day.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('staff-pick-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Early'), findsOneWidget);
  });

  testWidgets('cancel removes the booking and updates the room status', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      store: FakeStore(
        bookings: [fakeBooking(1, 'room-1', DateTime(2026, 11, 10, 15))],
      ),
    );
    expect(find.text('Booked'), findsOneWidget);
    await openStaff(tester);

    await tester.tap(cancel(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.text('No bookings on this day.'), findsOneWidget);
    expect(store.bookings, isEmpty);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Booked'), findsNothing);
    expect(find.text('Available'), findsNWidgets(2));
  });

  testWidgets('tapping a booking asks to cancel; keeping leaves it', (
    tester,
  ) async {
    final store = await pumpApp(tester, store: storeWithSchedule());
    await openStaff(tester);

    await tester.tap(find.text('Early'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this booking?'), findsOneWidget);
    await tester.tap(find.text('Keep booking'));
    await tester.pumpAndSettle();

    expect(find.text('Early'), findsOneWidget);
    expect(store.bookings, hasLength(3));
  });

  testWidgets('a new booking appears in the Staff tab', (tester) async {
    await pumpApp(tester);
    await openStaff(tester);
    expect(find.text('No bookings on this day.'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('customer-name')),
      'Ayesha',
    );
    await tester.tap(find.byKey(const ValueKey('slot-1030')));
    await tester.pump();
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    await openStaff(tester);
    expect(find.text('Ayesha'), findsOneWidget);
  });
}
