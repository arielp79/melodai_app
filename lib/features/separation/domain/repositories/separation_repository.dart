import '../entities/separation_job.dart';

abstract class SeparationRepository {
  Future<SeparationJob> createJob({
    required String sha256,
    required String objectKey,
    required String fileName,
  });

  Future<SeparationJob> getJob(String jobId);
}
