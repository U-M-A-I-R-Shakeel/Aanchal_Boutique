import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

enum SlotState { available, selected, booked, past }

/// Grid of 30-minute time slots. Booked and past slots can't be tapped.
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.stateOf,
    required this.onSelected,
  });

  final List<DateTime> slots;
  final SlotState Function(DateTime slot) stateOf;
  final ValueChanged<DateTime> onSelected;

  static String keyFor(DateTime slot) =>
      'slot-${slot.hour.toString().padLeft(2, '0')}'
      '${slot.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisExtent: 44,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final slot = slots[i];
        return _SlotTile(
          key: ValueKey(keyFor(slot)),
          label: Formatters.time(slot),
          state: stateOf(slot),
          onTap: () => onSelected(slot),
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final SlotState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = state == SlotState.available || state == SlotState.selected;

    final (bg, fg, border) = switch (state) {
      SlotState.selected => (scheme.primary, scheme.onPrimary, scheme.primary),
      SlotState.available => (
        Colors.white,
        scheme.onSurface,
        scheme.outlineVariant,
      ),
      SlotState.booked || SlotState.past => (
        AppColors.slotDisabledBg,
        AppColors.slotDisabledFg,
        Colors.transparent,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      selected: state == SlotState.selected,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                decoration: state == SlotState.booked
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlotLegend extends StatelessWidget {
  const SlotLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color fill, Color border, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Colors.white, scheme.outlineVariant, AppStrings.legendAvailable),
        item(scheme.primary, scheme.primary, AppStrings.legendSelected),
        item(
          AppColors.slotDisabledBg,
          AppColors.slotDisabledBg,
          AppStrings.legendUnavailable,
        ),
      ],
    );
  }
}
