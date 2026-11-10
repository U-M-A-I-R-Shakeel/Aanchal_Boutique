import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/room.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      RoomStatus.available => (
        AppStrings.available,
        AppColors.available,
        AppColors.availableBg,
      ),
      RoomStatus.busy => (AppStrings.busy, AppColors.busy, AppColors.busyBg),
      RoomStatus.booked => (
        AppStrings.booked,
        AppColors.booked,
        AppColors.bookedBg,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
