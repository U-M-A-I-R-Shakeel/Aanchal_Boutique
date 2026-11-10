/// App-wide user-facing strings.
abstract final class AppStrings {
  static const appName = 'Aanchal Boutique';
  static const homeTitle = 'Fitting Rooms';
  static const homeSubtitle = 'Choose an available room to book';
  static const available = 'Available';
  static const busy = 'Busy';
  static const booked = 'Booked';
  static const loadFailed = "Couldn't load data.";
  static const retry = 'Retry';

  static const selectDate = 'Select date';
  static const selectTime = 'Select time';
  static const yourName = 'Your name';
  static const yourNameHint = 'e.g. Ayesha Khan';
  static const today = 'Today';
  static const confirmBooking = 'Confirm Booking';
  static const pickASlot = 'Pick a time slot to continue';
  static const enterName = 'Enter your name to continue';
  static const noSlotsLeft = 'No slots left on this day. Try another date.';
  static const slotTaken =
      'Sorry, that slot is no longer available. Please pick another.';
  static const nameRequired = 'Please enter your name.';
  static const saveFailed = "Couldn't save the booking. Please try again.";
  static const legendAvailable = 'Available';
  static const legendSelected = 'Selected';
  static const legendUnavailable = 'Unavailable';

  static const bookings = 'Bookings';
  static const upcoming = 'Upcoming';
  static const pastAndCancelled = 'Past & cancelled';
  static const noUpcoming = 'No upcoming bookings.';
  static const noHistory = 'No past or cancelled bookings yet.';
  static const cancel = 'Cancel';
  static const keepBooking = 'Keep booking';
  static const cancelBooking = 'Cancel booking';
  static const cancelBookingTitle = 'Cancel this booking?';
  static const bookingCancelled = 'Booking cancelled';
  static const alreadyCancelled = 'This booking was already cancelled.';
  static const cancelFailed = "Couldn't cancel the booking. Please try again.";
  static const cancelled = 'Cancelled';
  static const completed = 'Completed';

  static String roomIsBusy(String room) => '$room is busy right now.';
  static String bookRoom(String room) => 'Book $room';
  static String bookingConfirmed(String room, String when) =>
      '$room booked for $when';
  static String cancelBookingBody(String room, String when, String name) =>
      '$room on $when for $name.';
}
