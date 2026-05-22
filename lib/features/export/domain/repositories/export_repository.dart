import '../../../separation/domain/entities/separation_stem.dart';

class ExportResult {
  const ExportResult({required this.path, required this.fileCount});

  final String path;
  final int fileCount;
}

abstract class ExportRepository {
  Future<ExportResult> exportStem(SeparationStem stem, {required String fileName});

  Future<ExportResult> exportStemsZip({
    required List<SeparationStem> stems,
    required String zipFileName,
  });
}
