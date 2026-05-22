import '../../../separation/domain/entities/separation_stem.dart';
import '../repositories/export_repository.dart';

class ExportStemFile {
  ExportStemFile(this._repository);

  final ExportRepository _repository;

  Future<ExportResult> call(SeparationStem stem, {required String baseName}) =>
      _repository.exportStem(stem, fileName: baseName);
}
