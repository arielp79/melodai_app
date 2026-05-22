import '../../domain/entities/separation_job.dart';
import 'separation_stem_model.dart';

class SeparationJobModel extends SeparationJob {
  const SeparationJobModel({
    required super.jobId,
    required super.status,
    required super.progress,
    required super.sha256,
    required super.objectKey,
    required super.fileName,
    required super.phase,
    required super.cached,
    required super.stems,
    super.sourceAudioUrl,
    super.error,
    super.completedAt,
  });

  factory SeparationJobModel.fromJson(Map<String, dynamic> json) {
    final stemsJson = json['stems'] as List<dynamic>? ?? [];
    return SeparationJobModel(
      jobId: json['jobId'] as String,
      status: SeparationJobStatus.fromApi(json['status'] as String? ?? ''),
      progress: json['progress'] as int? ?? 0,
      sha256: json['sha256'] as String,
      objectKey: json['objectKey'] as String,
      fileName: json['fileName'] as String? ?? 'audio',
      phase: json['phase'] as int? ?? 1,
      cached: json['cached'] as bool? ?? false,
      stems: stemsJson
          .map((e) => SeparationStemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceAudioUrl: json['sourceAudioUrl'] as String?,
      error: json['error'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }
}
