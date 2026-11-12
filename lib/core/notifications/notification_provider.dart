import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// The initialised notification service. Overridden in `main()`.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(
    'notificationServiceProvider must be overridden',
  ),
);
