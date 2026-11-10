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
  final _nameController = TextEditingController();
  late final List<DateTime> _dates;
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _dates = BookingRules.bookableDates(ref.read(clockProvider)());
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// First day that still has a free slot (e.g. skip today when opened after
  /// the last slot has passed).
  DateTime _firstOpenDate(Set<DateTime> booked, DateTime now) =>
      _dates.firstWhere(
        (d) => BookingRules.slotsFor(
          d,
        ).any((s) => !BookingRules.isPast(s, now) && !booked.contains(s)),
        orElse: () => _dates.first,
      );

  void _selectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedSlot = null;
  });

  void _selectSlot(DateTime slot) => setState(() => _selectedSlot = slot);

  Future<void> _confirm(String roomName) async {
    final slot = _selectedSlot;
    if (slot == null || _submitting) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    void show(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    setState(() => _submitting = true);
    try {
      await ref
          .read(bookingsProvider.notifier)
          .book(
            roomId: widget.roomId,
            start: slot,
            customerName: _nameController.text,
          );
    } on BookingException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectedSlot = null;
      });
      show(e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      show(AppStrings.saveFailed);
      return;
    }

    navigator.pop();
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
    final room = ref
        .watch(roomsProvider)
        .value
        ?.where((r) => r.id == widget.roomId)
        .firstOrNull;
    final bookings = ref.watch(bookingsProvider);

    if (room == null || !bookings.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: bookings.hasError
              ? const Text(AppStrings.loadFailed)
              : const CircularProgressIndicator(),
        ),
      );
    }

    final now = ref.read(clockProvider)();
    final booked = ref.watch(bookedSlotsProvider(widget.roomId));
    final selectedDate = _selectedDate ??= _firstOpenDate(booked, now);
    final slots = BookingRules.slotsFor(selectedDate);

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
    final hasName = _nameController.text.trim().isNotEmpty;
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextField(
              key: const ValueKey('customer-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: AppStrings.yourName,
                hintText: AppStrings.yourNameHint,
                prefixIcon: Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(AppStrings.selectDate, style: sectionStyle),
          ),
          DateSelector(
            dates: _dates,
            selected: selectedDate,
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
        summary: switch ((_selectedSlot, hasName)) {
          (null, _) => AppStrings.pickASlot,
          (_, false) => AppStrings.enterName,
          (final slot?, true) => Formatters.dateAndTime(slot),
        },
        submitting: _submitting,
        onConfirm: _selectedSlot == null || !hasName || _submitting
            ? null
            : () => _confirm(room.name),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.summary,
    required this.submitting,
    required this.onConfirm,
  });

  final String summary;
  final bool submitting;
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
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          AppStrings.confirmBooking,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
