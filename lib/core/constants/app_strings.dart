/// App-wide user-facing strings.
abstract final class AppStrings {
  static const appName = 'Aanchal Boutique';
  static const homeTitle = 'Fitting Rooms';
  static const homeSubtitle = 'Choose an available room to book';
  static const available = 'Available';
  static const busy = 'Busy';
  static const booked = 'Booked';

  static const selectDate = 'Select date';
  static const selectTime = 'Select time';
  static const today = 'Today';
  static const confirmBooking = 'Confirm Booking';
  static const pickASlot = 'Pick a time slot to continue';
  static const noSlotsLeft = 'No slots left on this day. Try another date.';
  static const slotTaken =
      'Sorry, that slot is no longer available. Please pick another.';
  static const legendAvailable = 'Available';
  static const legendSelected = 'Selected';
  static const legendUnavailable = 'Unavailable';

  static String roomIsBusy(String room) => '$room is busy right now.';
  static String bookRoom(String room) => 'Book $room';
  static String bookingConfirmed(String room, String when) =>
      '$room booked for $when';
}
