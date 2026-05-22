class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
