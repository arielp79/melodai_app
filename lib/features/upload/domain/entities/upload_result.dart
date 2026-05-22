class UploadResult {
  const UploadResult({
    required this.sha256,
    required this.objectKey,
    required this.fileName,
    required this.cached,
  });

  final String sha256;
  final String objectKey;
  final String fileName;
  final bool cached;
}
