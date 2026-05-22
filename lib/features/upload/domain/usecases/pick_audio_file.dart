import '../entities/audio_file.dart';
import '../repositories/upload_repository.dart';

class PickAudioFile {
  const PickAudioFile(this._repository);

  final UploadRepository _repository;

  Future<AudioFile?> call() => _repository.pickAudioFile();
}
