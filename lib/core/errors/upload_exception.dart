/// Error de dominio para selección, hash o subida de audio.
class UploadException implements Exception {
  const UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
