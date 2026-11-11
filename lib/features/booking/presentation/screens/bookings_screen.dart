import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/presentation/providers/rooms_provider.dart';
import '../../domain/models/booking.dart';
import '../providers/bookings_provider.dart';
import '../widgets/cancel_booking_dialog.dart';

/// All bookings: upcoming ones (cancellable) and past ones.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final roomNames = {
      for (final r in ref.watch(roomsProvider).value ?? const []) r.id: r.name,
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.bookings)),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(bookingsProvider),
            child: const Text('${AppStrings.loadFailed} ${AppStrings.retry}'),
          ),
        ),
        data: (all) {
          final now = ref.read(clockProvider)();
          final upcoming = all.where((b) => b.isUpcoming(now)).toList()
            ..sort((a, b) => a.start.compareTo(b.start));
          final history = all.where((b) => !b.isUpcoming(now)).toList()
            ..sort((a, b) => b.start.compareTo(a.start));
          String roomName(Booking b) => roomNames[b.roomId] ?? b.roomId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionHeader(AppStrings.upcoming, upcoming.length),
              if (upcoming.isEmpty) const _EmptyText(AppStrings.noUpcoming),
              for (final b in upcoming)
                _BookingTile(
                  booking: b,
                  roomName: roomName(b),
                  trailing: TextButton(
                    key: ValueKey('cancel-${b.id}'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.busy,
                    ),
                    onPressed: () =>
                        confirmAndCancelBooking(context, ref, b, roomName(b)),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionHeader(AppStrings.past, history.length),
              if (history.isEmpty) const _EmptyText(AppStrings.noHistory),
              for (final b in history)
                _BookingTile(
                  booking: b,
                  roomName: roomName(b),
                  muted: true,
                  trailing: _Tag(
                    b.isConfirmed ? AppStrings.completed : AppStrings.cancelled,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.count);
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
    child: Text(
      '$title ($count)',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.roomName,
    required this.trailing,
    this.muted = false,
  });

  final Booking booking;
  final String roomName;
  final Widget trailing;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = !booking.isConfirmed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: muted
                    ? AppColors.slotDisabledBg
                    : theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.event_available,
                  size: 20,
                  color: muted
                      ? AppColors.slotDisabledFg
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$roomName · ${booking.customerName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.dateAndTime(booking.start),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.slotDisabledBg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.slotDisabledFg,
      ),
    ),
  );
}
