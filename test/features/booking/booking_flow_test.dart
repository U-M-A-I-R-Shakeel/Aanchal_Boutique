import 'package:aanchal_boutique/app.dart';
import 'package:aanchal_boutique/core/utils/clock.dart';
import 'package:aanchal_boutique/core/utils/formatters.dart';
import 'package:aanchal_boutique/features/booking/presentation/screens/booking_screen.dart';
import 'package:aanchal_boutique/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {DateTime? now}) async {
    tester.view.physicalSize = const Size(1179, 2556); // iPhone 16 Pro
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(
            () => now ?? DateTime(2026, 11, 10, 9),
          ),
        ],
        child: const AanchalBoutiqueApp(),
      ),
    );
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('tap room, pick slot, confirm, return home with Booked status', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingScreen), findsOneWidget);
    expect(find.text('Book Room 1'), findsOneWidget);
    expect(find.text('Confirm Booking'), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-1000')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-1730')), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);

    // 11:00 is already booked for Room 1 today: tapping it selects nothing.
    await tester.tap(find.byKey(const ValueKey('slot-1100')));
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('slot-1030')));
    await tester.pump();
    final when = Formatters.dateAndTime(DateTime(2026, 11, 10, 10, 30));
    expect(when, startsWith('Tue, 10 Nov at 10:30'));
    expect(find.text(when), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BookingScreen), findsNothing);
    expect(find.text('Room 1 booked for $when'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget); // Room 3
  });

  testWidgets('booked slot is greyed out when reopening the room', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Room 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-1'))); // tomorrow
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('slot-1500')));
    await tester.pump();
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Room 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('slot-1500')));
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('changing date clears the selected slot', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('slot-1030')));
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('date-3')));
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);
    expect(find.text('Pick a time slot to continue'), findsOneWidget);
  });

  testWidgets('tapping a busy room shows a message and stays home', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Room 2'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingScreen), findsNothing);
    expect(find.text('Room 2 is busy right now.'), findsOneWidget);
  });

  testWidgets('after closing time, booking screen opens on tomorrow', (
    tester,
  ) async {
    await pumpApp(tester, now: DateTime(2026, 11, 10, 19));
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('slot-1030')));
    await tester.pump();
    expect(
      find.text(Formatters.dateAndTime(DateTime(2026, 11, 11, 10, 30))),
      findsOneWidget,
    );
  });
}
