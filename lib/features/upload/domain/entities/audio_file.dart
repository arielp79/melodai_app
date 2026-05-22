class AudioFile {
  const AudioFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
}
