import '../../domain/entities/presigned_upload.dart';

class PresignedUploadModel extends PresignedUpload {
  const PresignedUploadModel({
    required super.uploadUrl,
    required super.objectKey,
    required super.contentType,
    super.headers,
    super.cached,
  });

  factory PresignedUploadModel.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        headers['$key'] = '$value';
      });
    }

    return PresignedUploadModel(
      uploadUrl: json['uploadUrl'] as String,
      objectKey: json['objectKey'] as String,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      headers: headers,
      cached: json['cached'] as bool? ?? false,
    );
  }
}
