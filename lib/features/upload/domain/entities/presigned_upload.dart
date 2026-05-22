class PresignedUpload {
  const PresignedUpload({
    required this.uploadUrl,
    required this.objectKey,
    required this.contentType,
    this.headers = const {},
    this.cached = false,
  });

  final String uploadUrl;
  final String objectKey;
  final String contentType;
  final Map<String, String> headers;
  final bool cached;
}
