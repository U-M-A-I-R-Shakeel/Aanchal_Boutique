import 'dart:convert';
import 'dart:io';

import 'package:aanchal_boutique_api/aanchal_boutique_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  // Tuesday 10 Nov 2026, 9:00 AM (before opening).
  var now = DateTime(2026, 11, 10, 9);
  late Handler api;

  setUp(() {
    now = DateTime(2026, 11, 10, 9);
    api = buildApi(BookingService(openApiDatabase(), clock: () => now));
  });

  Future<(int, Object?)> call(
    String method,
    String path, [
    Object? body,
  ]) async {
    final res = await api(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : (body is String ? body : jsonEncode(body)),
      ),
    );
    final text = await res.readAsString();
    return (res.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  String? errorCode(Object? body) =>
      ((body as Map)['error'] as Map?)?['code'] as String?;

  Map<String, Object?> booking(
    String room,
    String date,
    String time, [
    String name = 'Umair',
  ]) => {'roomId': room, 'date': date, 'time': time, 'customerName': name};

  test('GET /health', () async {
    final (status, body) = await call('GET', '/health');
    expect(status, 200);
    expect(body, {'status': 'ok'});
  });

  test('GET /rooms returns the three rooms with statuses', () async {
    final (status, body) = await call('GET', '/rooms');
    expect(status, 200);
    expect(body, [
      {'id': 'room-1', 'name': 'Room 1', 'status': 'available'},
      {'id': 'room-2', 'name': 'Room 2', 'status': 'busy'},
      {'id': 'room-3', 'name': 'Room 3', 'status': 'available'},
    ]);
  });

  test('GET /rooms/{id}/slots lists 16 slots with status', () async {
    await call('POST', '/bookings', booking('room-1', '2026-11-10', '11:00'));
    now = DateTime(2026, 11, 10, 10, 15);

    final (status, body) = await call(
      'GET',
      '/rooms/room-1/slots?date=2026-11-10',
    );
    expect(status, 200);
    final slots = (body as Map)['slots'] as List;
    expect(slots, hasLength(16));
    expect(slots.first, {'time': '10:00', 'status': 'past'});
    expect(slots[1], {'time': '10:30', 'status': 'available'});
    expect(slots[2], {'time': '11:00', 'status': 'booked'});
    expect(slots.last, {'time': '17:30', 'status': 'available'});
    expect((body['room'] as Map)['status'], 'booked');
  });

  test('POST /bookings creates a booking and marks the room booked', () async {
    final (status, body) = await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-11', '10:30', '  Umair  '),
    );
    expect(status, 201);
    body as Map;
    expect(body['id'], isA<int>());
    expect(body['roomId'], 'room-1');
    expect(body['roomName'], 'Room 1');
    expect(body['date'], '2026-11-11');
    expect(body['time'], '10:30');
    expect(body['customerName'], 'Umair');

    final (_, rooms) = await call('GET', '/rooms');
    expect(((rooms as List).first as Map)['status'], 'booked');

    final (s2, one) = await call('GET', '/bookings/${body['id']}');
    expect(s2, 200);
    expect(one, body);
  });

  test('POST /bookings rejects a double booking with 409', () async {
    await call('POST', '/bookings', booking('room-1', '2026-11-11', '10:30'));
    final (status, body) = await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-11', '10:30', 'Sufyan'),
    );
    expect(status, 409);
    expect(errorCode(body), 'slot_taken');

    // The same time in another room is fine.
    final (s3, _) = await call(
      'POST',
      '/bookings',
      booking('room-3', '2026-11-11', '10:30', 'Sufyan'),
    );
    expect(s3, 201);
  });

  test('POST /bookings validation errors', () async {
    Future<void> expectError(Object body, int status, String code) async {
      final (s, b) = await call('POST', '/bookings', body);
      expect(s, status, reason: '$body');
      expect(errorCode(b), code, reason: '$body');
    }

    await expectError(
      booking('room-2', '2026-11-11', '10:00'),
      409,
      'room_busy',
    );
    await expectError(
      booking('room-9', '2026-11-11', '10:00'),
      404,
      'room_not_found',
    );
    await expectError(
      booking('room-1', '2026-11-11', '10:15'),
      400,
      'invalid_slot',
    );
    await expectError(
      booking('room-1', '2026-11-11', '18:00'),
      400,
      'invalid_slot',
    );
    await expectError(
      booking('room-1', '2026-11-17', '10:00'),
      400,
      'invalid_slot',
    );
    await expectError(
      booking('room-1', '2026-02-30', '10:00'),
      400,
      'invalid_request',
    );
    await expectError(
      booking('room-1', '11/11/2026', '10:00'),
      400,
      'invalid_request',
    );
    await expectError(
      booking('room-1', '2026-11-11', '10:00', '   '),
      400,
      'invalid_request',
    );
    await expectError({'roomId': 'room-1'}, 400, 'invalid_request');
    await expectError('not json', 400, 'invalid_request');
    await expectError('[1, 2]', 400, 'invalid_request');

    now = DateTime(2026, 11, 10, 14);
    await expectError(
      booking('room-1', '2026-11-10', '13:00'),
      400,
      'slot_in_past',
    );
  });

  test('GET /bookings lists all, or one day sorted by time', () async {
    await call(
      'POST',
      '/bookings',
      booking('room-3', '2026-11-11', '15:00', 'Abdul Rehman'),
    );
    await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-11', '11:00', 'Sufyan'),
    );
    await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-12', '10:00', 'Umair'),
    );

    final (s1, day) = await call('GET', '/bookings?date=2026-11-11');
    expect(s1, 200);
    expect(
      [for (final b in day as List) (b as Map)['customerName']],
      ['Sufyan', 'Abdul Rehman'],
    );

    final (_, all) = await call('GET', '/bookings');
    expect(all as List, hasLength(3));

    final (s3, bad) = await call('GET', '/bookings?date=tomorrow');
    expect(s3, 400);
    expect(errorCode(bad), 'invalid_request');
  });

  test('DELETE /bookings/{id} cancels and frees the room', () async {
    final (_, created) = await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-11', '10:30'),
    );
    final id = (created as Map)['id'];

    final (s1, b1) = await call('DELETE', '/bookings/$id');
    expect(s1, 204);
    expect(b1, isNull);

    final (_, rooms) = await call('GET', '/rooms');
    expect(((rooms as List).first as Map)['status'], 'available');

    final (s2, b2) = await call('DELETE', '/bookings/$id');
    expect(s2, 404);
    expect(errorCode(b2), 'booking_not_found');

    final (s3, _) = await call('GET', '/bookings/$id');
    expect(s3, 404);

    // The freed slot can be booked again.
    final (s4, _) = await call(
      'POST',
      '/bookings',
      booking('room-1', '2026-11-11', '10:30'),
    );
    expect(s4, 201);
  });

  test('a room goes back to available once its bookings have ended', () async {
    await call('POST', '/bookings', booking('room-3', '2026-11-10', '10:00'));
    final (_, before) = await call('GET', '/rooms');
    expect(((before as List)[2] as Map)['status'], 'booked');

    now = DateTime(2026, 11, 10, 10, 31);
    final (_, after) = await call('GET', '/rooms');
    expect(((after as List)[2] as Map)['status'], 'available');
  });

  test('unknown endpoints and bad ids', () async {
    final (s1, b1) = await call('GET', '/nope');
    expect(s1, 404);
    expect(errorCode(b1), 'not_found');
    final (s2, b2) = await call('GET', '/bookings/abc');
    expect(s2, 400);
    expect(errorCode(b2), 'invalid_request');
    final (s3, b3) = await call('GET', '/rooms/room-9/slots?date=2026-11-10');
    expect(s3, 404);
    expect(errorCode(b3), 'room_not_found');
  });

  test('bookings survive a restart (database file)', () async {
    final dir = Directory.systemTemp.createTempSync('api_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/api.db';

    var service = BookingService(openApiDatabase(path: path), clock: () => now);
    service.create(booking('room-1', '2026-11-11', '10:30'));

    service = BookingService(openApiDatabase(path: path), clock: () => now);
    expect(service.bookings(), hasLength(1));
    expect(service.rooms().first['status'], 'booked');
  });
}
