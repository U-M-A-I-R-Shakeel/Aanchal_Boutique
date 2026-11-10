import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';

/// Horizontal strip of selectable dates (the next 7 days).
class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.dates,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _DateChip(
          key: ValueKey('date-$i'),
          date: dates[i],
          isToday: i == 0,
          isSelected: dates[i] == selected,
          onTap: () => onSelected(dates[i]),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    super.key,
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = isSelected ? scheme.onPrimary : scheme.onSurface;
    final subtle = isSelected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? scheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isToday ? AppStrings.today : Formatters.weekday(date),
                  style: TextStyle(fontSize: 12, color: subtle),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.day(date),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                Text(
                  Formatters.month(date),
                  style: TextStyle(fontSize: 12, color: subtle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
