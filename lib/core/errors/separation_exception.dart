class SeparationException implements Exception {
  const SeparationException(this.message);

  final String message;

  @override
  String toString() => message;
}
