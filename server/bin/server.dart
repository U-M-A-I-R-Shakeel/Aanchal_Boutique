import 'dart:io';

import 'package:aanchal_boutique_api/aanchal_boutique_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Starts the API.
///   PORT     port to listen on (default 8080)
///   DB_PATH  SQLite file (default aanchal_boutique_api.db)
Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dbPath = Platform.environment['DB_PATH'] ?? 'aanchal_boutique_api.db';
  final service = BookingService(openApiDatabase(path: dbPath));

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(buildApi(service));
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print(
    'Aanchal Boutique API on http://localhost:${server.port} (db: $dbPath)',
  );
}
