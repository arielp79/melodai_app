import '../entities/audio_file.dart';
import '../entities/upload_result.dart';

abstract class UploadRepository {
  Future<AudioFile?> pickAudioFile();

  Future<UploadResult> uploadAudio(AudioFile file);
}
