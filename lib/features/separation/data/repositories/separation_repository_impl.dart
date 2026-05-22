import '../../domain/entities/separation_job.dart';
import '../../domain/repositories/separation_repository.dart';
import '../datasources/separation_api_datasource.dart';

class SeparationRepositoryImpl implements SeparationRepository {
  SeparationRepositoryImpl(this._api);

  final SeparationApiDataSource _api;

  @override
  Future<SeparationJob> createJob({
    required String sha256,
    required String objectKey,
    required String fileName,
  }) =>
      _api.createJob(
        sha256: sha256,
        objectKey: objectKey,
        fileName: fileName,
      );

  @override
  Future<SeparationJob> getJob(String jobId) => _api.getJob(jobId);
}
