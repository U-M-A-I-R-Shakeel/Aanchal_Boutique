/// A booking couldn't be made or changed. [message] is safe to show users.
class BookingException implements Exception {
  const BookingException(this.message);
  final String message;

  @override
  String toString() => 'BookingException: $message';
}
