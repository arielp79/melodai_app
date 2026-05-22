import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/upload_exception.dart';
import '../models/presigned_upload_model.dart';

/// Solicita al orquestador Node.js una URL firmada para subir al bucket.
class UploadApiDataSource {
  UploadApiDataSource(this._client);

  final http.Client _client;

  Future<PresignedUploadModel> requestPresignedUpload({
    required String fileName,
    required String contentType,
    required String sha256,
    required int sizeBytes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/uploads/presign');

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fileName': fileName,
        'contentType': contentType,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PresignedUploadModel.fromJson(json);
    }

    if (response.statusCode == 409) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PresignedUploadModel.fromJson(json);
    }

    throw UploadException(_parseApiError(
      statusCode: response.statusCode,
      body: response.body,
      fallback: 'Error al solicitar URL de subida',
    ));
  }

  String _parseApiError({
    required int statusCode,
    required String body,
    required String fallback,
  }) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as String? ?? fallback;
      final detail = json['detail'] as String?;
      final hint = json['hint'] as String?;
      final parts = <String>[error];
      if (detail != null && detail.isNotEmpty) parts.add(detail);
      if (hint != null && hint.isNotEmpty) parts.add(hint);
      if (parts.length > 1) return parts.join(' — ');
      return '$error (HTTP $statusCode)';
    } catch (_) {
      return '$fallback (HTTP $statusCode): $body';
    }
  }

  /// Registra en el orquestador que la subida al bucket terminó (activa dedup).
  Future<void> completeUpload({
    required String sha256,
    required String objectKey,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/uploads/complete');

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sha256': sha256,
        'objectKey': objectKey,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw UploadException(_parseApiError(
      statusCode: response.statusCode,
      body: response.body,
      fallback: 'Error al confirmar la subida',
    ));
  }
}
