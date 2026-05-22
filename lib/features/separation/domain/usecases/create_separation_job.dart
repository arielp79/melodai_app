import '../entities/separation_job.dart';
import '../repositories/separation_repository.dart';

class CreateSeparationJob {
  const CreateSeparationJob(this._repository);

  final SeparationRepository _repository;

  Future<SeparationJob> call({
    required String sha256,
    required String objectKey,
    required String fileName,
  }) =>
      _repository.createJob(
        sha256: sha256,
        objectKey: objectKey,
        fileName: fileName,
      );
}
