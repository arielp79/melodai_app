import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/upload_exception.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/usecases/pick_audio_file.dart';
import '../../domain/usecases/upload_audio_file.dart';

enum UploadPhase { idle, picking, uploading, success, error }

class UploadViewModel extends ChangeNotifier {
  UploadViewModel({
    required PickAudioFile pickAudioFile,
    required UploadAudioFile uploadAudioFile,
  })  : _pickAudioFile = pickAudioFile,
        _uploadAudioFile = uploadAudioFile;

  final PickAudioFile _pickAudioFile;
  final UploadAudioFile _uploadAudioFile;

  UploadPhase phase = UploadPhase.idle;
  AudioFile? selectedFile;
  UploadResult? lastResult;
  String? errorMessage;
  String? statusMessage;

  bool get isBusy =>
      phase == UploadPhase.picking || phase == UploadPhase.uploading;

  Future<void> pickFile() async {
    phase = UploadPhase.picking;
    errorMessage = null;
    lastResult = null;
    statusMessage = null;
    notifyListeners();

    try {
      selectedFile = await _pickAudioFile();
      phase = UploadPhase.idle;
    } on UploadException catch (e) {
      phase = UploadPhase.error;
      errorMessage = e.message;
    } catch (_) {
      phase = UploadPhase.error;
      errorMessage = 'No se pudo seleccionar el archivo.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> uploadSelected() async {
    final file = selectedFile;
    if (file == null) {
      errorMessage = 'Selecciona un archivo de audio primero.';
      phase = UploadPhase.error;
      notifyListeners();
      return;
    }

    phase = UploadPhase.uploading;
    errorMessage = null;
    lastResult = null;
    statusMessage = 'Calculando SHA-256 y subiendo…';
    notifyListeners();

    try {
      lastResult = await _uploadAudioFile(file);
      phase = UploadPhase.success;
      statusMessage = lastResult!.cached
          ? 'Canción ya procesada (caché por hash).'
          : 'Subida completada correctamente.';
    } on UploadException catch (e) {
      phase = UploadPhase.error;
      errorMessage = e.message;
      statusMessage = null;
    } catch (e, stack) {
      phase = UploadPhase.error;
      errorMessage = _mapUnexpectedUploadError(e);
      statusMessage = null;
      debugPrint('Upload error: $e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  String _mapUnexpectedUploadError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Connection refused') ||
        text.contains('Failed host lookup')) {
      return 'No se pudo conectar al servidor. ¿Está corriendo el backend en ${ApiConfig.baseUrl}?';
    }
    if (text.contains('No hay sesión activa')) {
      return 'Sesión expirada. Cierra sesión e inicia de nuevo.';
    }
    if (text.contains('Connection closed') ||
        text.contains('Connection reset') ||
        text.contains('full header')) {
      return 'El servidor cerró la conexión antes de responder. '
          'Comprueba que el backend sigue en marcha (npm run dev en backend/) '
          'y que no se reinició al guardar archivos; si persiste, usa npm start '
          'en lugar de npm run dev e inténtalo de nuevo.';
    }
    return 'Error inesperado durante la subida: $text';
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    if (phase == UploadPhase.error) {
      phase = UploadPhase.idle;
    }
    notifyListeners();
  }
}
