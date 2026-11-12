import 'package:aanchal_boutique/app.dart';
import 'package:aanchal_boutique/core/notifications/notification_provider.dart';
import 'package:aanchal_boutique/core/utils/clock.dart';
import 'package:aanchal_boutique/features/booking/presentation/providers/bookings_provider.dart';
import 'package:aanchal_boutique/features/home/presentation/providers/rooms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notifications.dart';
import 'fakes.dart';

final defaultNow = DateTime(2026, 11, 10, 9); // Tue, before opening

/// Pumps the full app at iPhone 16 Pro size, backed by an in-memory store.
Future<FakeStore> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  FakeStore? store,
  FakeNotificationService? notifications,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final s = store ?? FakeStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now ?? defaultNow),
        roomRepositoryProvider.overrideWithValue(FakeRoomRepository(s)),
        bookingRepositoryProvider.overrideWithValue(FakeBookingRepository(s)),
        notificationServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationService(),
        ),
      ],
      child: const AanchalBoutiqueApp(),
    ),
  );
  await tester.pumpAndSettle();
  return s;
}
