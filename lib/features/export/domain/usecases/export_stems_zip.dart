import '../../../separation/domain/entities/separation_job.dart';
import '../repositories/export_repository.dart';

class ExportStemsZip {
  ExportStemsZip(this._repository);

  final ExportRepository _repository;

  Future<ExportResult> call(SeparationJob job) {
    final safeName = _safeBaseName(job.fileName);
    return _repository.exportStemsZip(
      stems: job.stems,
      zipFileName: safeName,
    );
  }

  String _safeBaseName(String name) {
    final base = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return base.isEmpty ? 'melodai-export' : base;
  }
}
