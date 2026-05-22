import 'package:flutter/foundation.dart';

import '../../../../core/errors/export_exception.dart';
import '../../../../core/errors/separation_exception.dart';
import '../../../separation/domain/entities/separation_job.dart'
    show SeparationJob, SeparationJobStatus;
import '../../../separation/domain/entities/separation_stem.dart';
import '../../../separation/domain/usecases/get_separation_job.dart';
import '../../domain/usecases/export_stem_file.dart';
import '../../domain/usecases/export_stems_zip.dart';

enum ExportPhase { idle, loading, ready, exporting, done, error }

class ExportViewModel extends ChangeNotifier {
  ExportViewModel({
    required GetSeparationJob getSeparationJob,
    required ExportStemFile exportStemFile,
    required ExportStemsZip exportStemsZip,
  })  : _getSeparationJob = getSeparationJob,
        _exportStemFile = exportStemFile,
        _exportStemsZip = exportStemsZip;

  final GetSeparationJob _getSeparationJob;
  final ExportStemFile _exportStemFile;
  final ExportStemsZip _exportStemsZip;

  ExportPhase phase = ExportPhase.idle;
  SeparationJob? job;
  String? errorMessage;
  String? successMessage;

  int get playableCount =>
      job?.stems.where((s) => _hasAudio(s)).length ?? 0;

  bool get canExport => phase == ExportPhase.ready && playableCount > 0;

  Future<void> load(String jobId) async {
    phase = ExportPhase.loading;
    errorMessage = null;
    successMessage = null;
    job = null;
    notifyListeners();

    try {
      final loaded = await _getSeparationJob(jobId);
      if (loaded.status != SeparationJobStatus.completed) {
        phase = ExportPhase.error;
        errorMessage = 'El job aún no está completado (estado: ${loaded.status.name}).';
        return;
      }
      job = loaded;
      phase = ExportPhase.ready;
    } on SeparationException catch (e) {
      phase = ExportPhase.error;
      errorMessage = e.message;
    } catch (e) {
      phase = ExportPhase.error;
      errorMessage = 'No se pudo cargar el job: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> exportZip() async {
    final current = job;
    if (current == null) return;

    phase = ExportPhase.exporting;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final result = await _exportStemsZip(current);
      phase = ExportPhase.done;
      successMessage =
          'ZIP guardado (${result.fileCount} pistas):\n${result.path}';
    } on ExportException catch (e) {
      phase = ExportPhase.ready;
      errorMessage = e.message;
    } catch (e) {
      phase = ExportPhase.ready;
      errorMessage = 'Error al exportar ZIP: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> exportOne(SeparationStem stem) async {
    final current = job;
    if (current == null) return;

    phase = ExportPhase.exporting;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final result = await _exportStemFile(
        stem,
        baseName: current.fileName,
      );
      phase = ExportPhase.done;
      successMessage = 'Guardado: ${result.path}';
    } on ExportException catch (e) {
      phase = ExportPhase.ready;
      errorMessage = e.message;
    } catch (e) {
      phase = ExportPhase.ready;
      errorMessage = 'Error al exportar: $e';
    } finally {
      notifyListeners();
    }
  }

  bool _hasAudio(SeparationStem stem) =>
      stem.downloadUrl != null && stem.downloadUrl!.isNotEmpty;
}
