class SeparationStem {
  const SeparationStem({
    required this.id,
    required this.label,
    required this.objectKey,
    required this.phase,
    this.simulated = false,
    this.downloadUrl,
  });

  final String id;
  final String label;
  final String objectKey;
  final int phase;
  final bool simulated;
  final String? downloadUrl;
}
