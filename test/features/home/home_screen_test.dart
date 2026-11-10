import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Home screen shows rooms loaded from storage', (tester) async {
    await pumpApp(tester);

    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('Room 2'), findsOneWidget);
    expect(find.text('Room 3'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Busy'), findsOneWidget);
  });

  testWidgets('Home screen shows stored Booked status', (tester) async {
    await pumpApp(
      tester,
      store: FakeStore(
        bookings: [fakeBooking(1, 'room-3', DateTime(2026, 11, 12, 15))],
      ),
    );
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('room whose bookings have ended goes back to Available', (
    tester,
  ) async {
    await pumpApp(
      tester,
      store: FakeStore(
        rooms: const [
          Room(id: 'room-1', name: 'Room 1', status: RoomStatus.booked),
        ],
        bookings: [fakeBooking(1, 'room-1', DateTime(2026, 11, 9, 15))],
      ),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Booked'), findsNothing);
  });
}
