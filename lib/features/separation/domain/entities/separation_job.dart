import 'separation_stem.dart';

enum SeparationJobStatus {
  queued,
  processing,
  completed,
  failed,
  unknown;

  static SeparationJobStatus fromApi(String value) {
    return switch (value) {
      'queued' => SeparationJobStatus.queued,
      'processing' => SeparationJobStatus.processing,
      'completed' => SeparationJobStatus.completed,
      'failed' => SeparationJobStatus.failed,
      _ => SeparationJobStatus.unknown,
    };
  }

  bool get isTerminal =>
      this == SeparationJobStatus.completed ||
      this == SeparationJobStatus.failed;
}

class SeparationJob {
  const SeparationJob({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.sha256,
    required this.objectKey,
    required this.fileName,
    required this.phase,
    required this.cached,
    required this.stems,
    this.sourceAudioUrl,
    this.error,
    this.completedAt,
  });

  final String jobId;
  final SeparationJobStatus status;
  final int progress;
  final String sha256;
  final String objectKey;
  final String fileName;
  final int phase;
  final bool cached;
  final List<SeparationStem> stems;
  /// URL firmada del mix original subido (siempre reproducible tras la subida).
  final String? sourceAudioUrl;
  final String? error;
  final String? completedAt;
}
