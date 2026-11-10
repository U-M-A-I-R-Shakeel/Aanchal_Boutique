import 'package:aanchal_boutique/app.dart';
import 'package:aanchal_boutique/features/home/domain/models/room.dart';
import 'package:aanchal_boutique/features/home/presentation/providers/rooms_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roomsProvider exposes three static rooms', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rooms = container.read(roomsProvider);
    expect(rooms.map((r) => r.name), ['Room 1', 'Room 2', 'Room 3']);
  });

  testWidgets('Home screen shows three room cards with status badges',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AanchalBoutiqueApp()));

    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('Room 2'), findsOneWidget);
    expect(find.text('Room 3'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Busy'), findsOneWidget);
  });

  testWidgets('Home screen reflects overridden room state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomsProvider.overrideWithBuild(
            (ref, notifier) => const [
              Room(id: 'x', name: 'Room X', status: RoomStatus.busy),
            ],
          ),
        ],
        child: const AanchalBoutiqueApp(),
      ),
    );

    expect(find.text('Room X'), findsOneWidget);
    expect(find.text('Busy'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
  });
}
