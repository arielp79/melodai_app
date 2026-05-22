import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/export_exception.dart';
import '../../../separation/domain/entities/separation_stem.dart';
import '../../domain/repositories/export_repository.dart';

class StemFileExporter implements ExportRepository {
  StemFileExporter({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<int>> _download(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw ExportException(
        'No se pudo descargar el audio (HTTP ${response.statusCode}).',
      );
    }
    return response.bodyBytes;
  }

  Future<String?> _pickSavePath(String suggestedName) {
    return FilePicker.saveFile(
      dialogTitle: 'Guardar archivo',
      fileName: suggestedName,
    );
  }

  @override
  Future<ExportResult> exportStem(
    SeparationStem stem, {
    required String fileName,
  }) async {
    final url = stem.downloadUrl;
    if (url == null || url.isEmpty) {
      throw ExportException(
        'La pista "${stem.label}" no tiene audio en el bucket (stub o job incompleto).',
      );
    }

    final savePath = await _pickSavePath('${stem.id}.wav');
    if (savePath == null) {
      throw ExportException('Exportación cancelada.');
    }

    final bytes = await _download(url);
    await File(savePath).writeAsBytes(bytes);

    return ExportResult(path: savePath, fileCount: 1);
  }

  @override
  Future<ExportResult> exportStemsZip({
    required List<SeparationStem> stems,
    required String zipFileName,
  }) async {
    final playable = stems
        .where((s) => s.downloadUrl != null && s.downloadUrl!.isNotEmpty)
        .toList();

    if (playable.isEmpty) {
      throw ExportException(
        'No hay pistas con audio para exportar. Ejecuta HTDemucs en el worker.',
      );
    }

    final savePath = await _pickSavePath('$zipFileName-stems.zip');
    if (savePath == null) {
      throw ExportException('Exportación cancelada.');
    }

    final archive = Archive();
    for (final stem in playable) {
      final bytes = await _download(stem.downloadUrl!);
      archive.addFile(
        ArchiveFile('${stem.id}.wav', bytes.length, bytes),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes.isEmpty) {
      throw ExportException('No se pudo crear el archivo ZIP.');
    }

    await File(savePath).writeAsBytes(zipBytes);

    return ExportResult(path: savePath, fileCount: playable.length);
  }
}
