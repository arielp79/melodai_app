import '../entities/separation_job.dart';
import '../repositories/separation_repository.dart';

class GetSeparationJob {
  const GetSeparationJob(this._repository);

  final SeparationRepository _repository;

  Future<SeparationJob> call(String jobId) => _repository.getJob(jobId);
}
