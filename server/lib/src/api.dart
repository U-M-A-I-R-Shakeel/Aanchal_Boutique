import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'booking_service.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

Response _ok(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _json);

Response _error(int status, String code, String message) => _ok({
  'error': {'code': code, 'message': message},
}, status: status);

/// All API routes. See README "API documentation" and the Postman collection
/// in `postman/`.
Handler buildApi(BookingService service) {
  final router =
      Router(
          notFoundHandler: (_) => _error(404, 'not_found', 'Unknown endpoint.'),
        )
        ..get('/health', (Request _) => _ok({'status': 'ok'}))
        ..get('/rooms', (Request _) => _ok(service.rooms()))
        ..get(
          '/rooms/<id>/slots',
          (Request r, String id) =>
              _ok(service.slots(id, r.url.queryParameters['date'])),
        )
        ..get(
          '/bookings',
          (Request r) =>
              _ok(service.bookings(dateText: r.url.queryParameters['date'])),
        )
        ..get(
          '/bookings/<id>',
          (Request _, String id) => _ok(service.booking(_id(id))),
        )
        ..post('/bookings', (Request r) async {
          final Object? body;
          try {
            body = jsonDecode(await r.readAsString());
          } on FormatException {
            throw const ApiException(
              400,
              'invalid_request',
              'Body must be JSON.',
            );
          }
          if (body is! Map<String, Object?>) {
            throw const ApiException(
              400,
              'invalid_request',
              'Body must be a JSON object.',
            );
          }
          return _ok(service.create(body), status: 201);
        })
        ..delete('/bookings/<id>', (Request _, String id) {
          service.cancel(_id(id));
          return Response(204);
        });

  return const Pipeline().addMiddleware(_errors).addHandler(router.call);
}

int _id(String s) =>
    int.tryParse(s) ??
    (throw const ApiException(
      400,
      'invalid_request',
      'Booking id must be a number.',
    ));

/// Turns [ApiException]s into JSON errors, and anything else into a 500.
Handler _errors(Handler inner) => (request) async {
  try {
    return await inner(request);
  } on ApiException catch (e) {
    return _error(e.status, e.code, e.message);
  } catch (e) {
    return _error(500, 'server_error', 'Something went wrong.');
  }
};
