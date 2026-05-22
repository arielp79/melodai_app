import '../entities/audio_file.dart';
import '../entities/upload_result.dart';
import '../repositories/upload_repository.dart';

class UploadAudioFile {
  const UploadAudioFile(this._repository);

  final UploadRepository _repository;

  Future<UploadResult> call(AudioFile file) => _repository.uploadAudio(file);
}
