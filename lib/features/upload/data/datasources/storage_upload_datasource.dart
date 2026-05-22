import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/errors/upload_exception.dart';

/// Sube el archivo directamente al bucket usando la presigned URL.
class StorageUploadDataSource {
  StorageUploadDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> uploadToPresignedUrl({
    required Uri uploadUrl,
    required File file,
    required String contentType,
    Map<String, String> headers = const {},
  }) async {
    final length = await file.length();
    final request = http.StreamedRequest('PUT', uploadUrl)
      ..contentLength = length
      ..headers['Content-Type'] = contentType;

    for (final entry in headers.entries) {
      request.headers[entry.key] = entry.value;
    }

    final uploadFuture = _client.send(request);
    await request.sink.addStream(file.openRead());
    await request.sink.close();

    final response = await uploadFuture;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw UploadException(
        'Error al subir al almacenamiento (${response.statusCode}): $body',
      );
    }
  }
}
