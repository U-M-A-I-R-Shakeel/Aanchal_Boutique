import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../booking/domain/models/booking.dart';
import '../../../booking/presentation/providers/bookings_provider.dart';
import '../../../booking/presentation/widgets/cancel_booking_dialog.dart';
import '../../../home/presentation/providers/rooms_provider.dart';

/// The boutique owner's view: every booking on the selected day, by time.
class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  late final DateTime _today;
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _today = ref.read(clockProvider)().dateOnly;
    _firstDate = DateTime(_today.year - 1, _today.month, _today.day);
    _lastDate = DateTime(_today.year + 1, _today.month, _today.day);
    _selected = _today;
  }

  void _shiftDay(int days) => setState(() {
    _selected = DateTime(_selected.year, _selected.month, _selected.day + days);
  });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: _firstDate,
      lastDate: _lastDate,
      currentDate: _today,
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsForDateProvider(_selected));
    final roomNames = {
      for (final r in ref.watch(roomsProvider).value ?? const []) r.id: r.name,
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.staffTitle)),
      body: Column(
        children: [
          _DayPicker(
            label: _selected == _today
                ? '${AppStrings.today} · ${Formatters.fullDate(_selected)}'
                : Formatters.fullDate(_selected),
            onPrevious: _selected.isAfter(_firstDate)
                ? () => _shiftDay(-1)
                : null,
            onNext: _selected.isBefore(_lastDate) ? () => _shiftDay(1) : null,
            onPick: _pickDate,
          ),
          Expanded(
            child: bookings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(bookingsForDateProvider),
                  child: const Text(
                    '${AppStrings.loadFailed} ${AppStrings.retry}',
                  ),
                ),
              ),
              data: (day) {
                if (day.isEmpty) {
                  return const Center(child: Text(AppStrings.noBookingsOnDay));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: day.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final booking = day[i];
                    final room = roomNames[booking.roomId] ?? booking.roomId;
                    return _ScheduleCard(
                      booking: booking,
                      roomName: room,
                      onCancel: () =>
                          confirmAndCancelBooking(context, ref, booking, room),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.previousDay,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: TextButton.icon(
              key: const ValueKey('staff-pick-date'),
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextDay,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.booking,
    required this.roomName,
    required this.onCancel,
  });

  final Booking booking;
  final String roomName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCancel,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  Formatters.time(booking.start),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roomName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: ValueKey('staff-cancel-${booking.id}'),
                style: TextButton.styleFrom(foregroundColor: AppColors.busy),
                onPressed: onCancel,
                child: const Text(AppStrings.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
