// End-to-end check on a real device or simulator:
//   flutter test integration_test -d <device>
//
// Uses its own database file, so the app's real data is never touched.
import 'package:aanchal_boutique/app.dart';
import 'package:aanchal_boutique/core/database/app_database.dart';
import 'package:aanchal_boutique/core/database/database_provider.dart';
import 'package:aanchal_boutique/core/notifications/local_notification_service.dart';
import 'package:aanchal_boutique/core/notifications/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String dbPath;
  final notifications = LocalNotificationService();

  setUpAll(() async {
    dbPath = p.join(await getDatabasesPath(), 'e2e_test.db');
    await deleteDatabase(dbPath);
    await notifications.init(onTap: (_) {});
  });
  tearDownAll(() => deleteDatabase(dbPath));

  /// Starts the app on [db], like a fresh launch.
  Future<void> launch(WidgetTester tester, Database db) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const AanchalBoutiqueApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<PendingNotificationRequest>> pending() =>
      FlutterLocalNotificationsPlugin().pendingNotificationRequests();

  FilledButton confirm(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('book, persist, remind, staff cancel', (tester) async {
    var db = await AppDatabase.open(path: dbPath);
    await launch(tester, db);

    // Home
    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Busy'), findsOneWidget);

    // Busy room doesn't open
    await tester.tap(find.text('Room 2'));
    await tester.pumpAndSettle();
    expect(find.text('Room 2 is busy right now.'), findsOneWidget);

    // Book Room 1 tomorrow at 3:00 PM
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();
    expect(find.text('Book Room 1'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('customer-name')),
      'E2E Umair',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.byKey(const ValueKey('date-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-1500')));
    await tester.pumpAndSettle();
    expect(confirm(tester).onPressed, isNotNull);
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Book Room 1'), findsNothing);
    expect(find.textContaining('Room 1 booked for'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);

    // Saved in SQLite
    final rows = await db.query('bookings');
    expect(rows, hasLength(1));
    expect(rows.single['customer_name'], 'E2E Umair');
    expect(rows.single['start_time'], '15:00');
    final id = rows.single['id']! as int;

    // Reminder scheduled with the OS
    var reminders = await pending();
    final mine = reminders.where((r) => r.id == id).toList();
    expect(mine, hasLength(1));
    expect(mine.single.body, startsWith('Fitting Room 1 at 3:00'));

    // The booked slot can't be picked again
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-1500')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a time slot to continue'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // "Restart": close the database and launch again on the same file
    await db.close();
    db = await AppDatabase.open(path: dbPath);
    await launch(tester, db);
    expect(find.text('Booked'), findsOneWidget);
    await tester.tap(find.byTooltip('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Room 1 · E2E Umair'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Staff tab: tomorrow's schedule, cancel the booking
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('E2E Umair'), findsOneWidget);
    expect(find.text('Room 1'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('staff-cancel-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();
    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.text('No bookings on this day.'), findsOneWidget);

    // Row deleted, reminder cancelled, room free again
    expect(await db.query('bookings'), isEmpty);
    reminders = await pending();
    expect(reminders.where((r) => r.id == id), isEmpty);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Booked'), findsNothing);
    expect(find.text('Available'), findsNWidgets(2));

    await db.close();
  });
}
