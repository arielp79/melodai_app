import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/audio_formats.dart';
import '../../../../core/errors/upload_exception.dart';
import '../../domain/entities/audio_file.dart';

class AudioFilePickerDataSource {
  Future<AudioFile?> pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AudioFormats.extensions,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.single;
    final path = platformFile.path;

    if (path == null) {
      throw const UploadException(
        'No se pudo acceder al archivo seleccionado. '
        'En esta plataforma usa la app en Windows, Android o iOS.',
      );
    }

    final name = platformFile.name;
    final extension = _extensionFromName(name);

    if (!AudioFormats.isAllowedExtension(extension)) {
      throw UploadException(
        'Formato no permitido. Usa: ${AudioFormats.extensions.join(', ')}',
      );
    }

    final sizeBytes = platformFile.size;
    if (sizeBytes <= 0) {
      throw const UploadException(
        'No se pudo determinar el tamaño del archivo.',
      );
    }

    return AudioFile(
      path: path,
      name: name,
      extension: extension,
      sizeBytes: sizeBytes,
    );
  }

  String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex + 1).toLowerCase();
  }
}
