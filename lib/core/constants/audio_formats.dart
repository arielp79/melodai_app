/// Formatos de audio admitidos según el PRD.
abstract final class AudioFormats {
  static const extensions = ['mp3', 'wav', 'flac', 'm4a'];

  static bool isAllowedExtension(String extension) {
    return extensions.contains(extension.toLowerCase());
  }
}
