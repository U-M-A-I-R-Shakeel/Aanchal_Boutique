import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/presentation/providers/rooms_provider.dart';
import '../../domain/booking_rules.dart';
import '../providers/bookings_provider.dart';
import '../widgets/date_selector.dart';
import '../widgets/time_slot_grid.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  DateTime? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final booked = ref.read(bookedSlotsProvider(widget.roomId));
    _dates = BookingRules.bookableDates(now);
    // Start on the first day that still has a free slot (e.g. skip today
    // when opened after the last slot has passed).
    _selectedDate = _dates.firstWhere(
      (d) => BookingRules.slotsFor(
        d,
      ).any((s) => !BookingRules.isPast(s, now) && !booked.contains(s)),
      orElse: () => _dates.first,
    );
  }

  void _selectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedSlot = null;
  });

  void _selectSlot(DateTime slot) => setState(() => _selectedSlot = slot);

  void _confirm(String roomName) {
    final slot = _selectedSlot;
    if (slot == null) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      ref
          .read(bookingsProvider.notifier)
          .book(roomId: widget.roomId, start: slot);
    } on BookingException catch (e) {
      setState(() => _selectedSlot = null);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.bookingConfirmed(
                    roomName,
                    Formatters.dateAndTime(slot),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider);
    final room = rooms.where((r) => r.id == widget.roomId).firstOrNull;
    if (room == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final now = ref.read(clockProvider)();
    final booked = ref.watch(bookedSlotsProvider(widget.roomId));
    final slots = BookingRules.slotsFor(_selectedDate);

    SlotState stateOf(DateTime slot) {
      if (booked.contains(slot)) return SlotState.booked;
      if (BookingRules.isPast(slot, now)) return SlotState.past;
      if (slot == _selectedSlot) return SlotState.selected;
      return SlotState.available;
    }

    final noneLeft = slots.every((s) {
      final st = stateOf(s);
      return st == SlotState.booked || st == SlotState.past;
    });
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.bookRoom(room.name))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(AppStrings.selectDate, style: sectionStyle),
          ),
          DateSelector(
            dates: _dates,
            selected: _selectedDate,
            onSelected: _selectDate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(AppStrings.selectTime, style: sectionStyle),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SlotLegend(),
          ),
          TimeSlotGrid(slots: slots, stateOf: stateOf, onSelected: _selectSlot),
          if (noneLeft)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                AppStrings.noSlotsLeft,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _ConfirmBar(
        summary: _selectedSlot == null
            ? AppStrings.pickASlot
            : Formatters.dateAndTime(_selectedSlot!),
        onConfirm: _selectedSlot == null ? null : () => _confirm(room.name),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.summary, required this.onConfirm});

  final String summary;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text(
                    AppStrings.confirmBooking,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
