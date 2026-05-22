import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/separation_exception.dart';
import '../models/separation_job_model.dart';

class SeparationApiDataSource {
  SeparationApiDataSource(this._client);

  final http.Client _client;

  Future<SeparationJobModel> createJob({
    required String sha256,
    required String objectKey,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/separation/jobs');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sha256': sha256,
        'objectKey': objectKey,
        'fileName': fileName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SeparationJobModel.fromJson(json);
    }

    throw SeparationException(_parseError(response));
  }

  Future<SeparationJobModel> getJob(String jobId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/separation/jobs/$jobId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SeparationJobModel.fromJson(json);
    }

    throw SeparationException(_parseError(response));
  }

  String _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as String? ?? 'Error de separación';
      final detail = json['detail'] as String?;
      if (detail != null && detail.isNotEmpty) {
        return '$error — $detail';
      }
      return '$error (HTTP ${response.statusCode})';
    } catch (_) {
      return 'Error de separación (HTTP ${response.statusCode})';
    }
  }
}
