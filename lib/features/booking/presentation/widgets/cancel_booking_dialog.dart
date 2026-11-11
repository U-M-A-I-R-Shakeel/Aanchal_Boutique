import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/booking.dart';
import '../providers/bookings_provider.dart';

/// Asks for confirmation, cancels [booking], and reports the result.
Future<void> confirmAndCancelBooking(
  BuildContext context,
  WidgetRef ref,
  Booking booking,
  String roomName,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.cancelBookingTitle),
      content: Text(
        AppStrings.cancelBookingBody(
          roomName,
          Formatters.dateAndTime(booking.start),
          booking.customerName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.keepBooking),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.busy),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AppStrings.cancelBooking),
        ),
      ],
    ),
  );
  if (ok != true) return;

  String message;
  try {
    await ref.read(bookingsProvider.notifier).cancel(booking);
    message = AppStrings.bookingCancelled;
  } on BookingException catch (e) {
    message = e.message;
  } catch (_) {
    message = AppStrings.cancelFailed;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
