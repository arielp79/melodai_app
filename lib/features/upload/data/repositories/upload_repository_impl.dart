import 'dart:io';

import '../../../../core/utils/file_hash_calculator.dart';
import '../../../../core/utils/mime_type_helper.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/audio_file_picker_datasource.dart';
import '../datasources/storage_upload_datasource.dart';
import '../datasources/upload_api_datasource.dart';

class UploadRepositoryImpl implements UploadRepository {
  UploadRepositoryImpl({
    required AudioFilePickerDataSource picker,
    required UploadApiDataSource uploadApi,
    required StorageUploadDataSource storageUpload,
    required FileHashCalculator hashCalculator,
  })  : _picker = picker,
        _uploadApi = uploadApi,
        _storageUpload = storageUpload,
        _hashCalculator = hashCalculator;

  final AudioFilePickerDataSource _picker;
  final UploadApiDataSource _uploadApi;
  final StorageUploadDataSource _storageUpload;
  final FileHashCalculator _hashCalculator;

  @override
  Future<AudioFile?> pickAudioFile() => _picker.pickAudioFile();

  @override
  Future<UploadResult> uploadAudio(AudioFile file) async {
    final diskFile = File(file.path);
    final contentType = MimeTypeHelper.fromFileName(file.name);
    final sha256 = await _hashCalculator.computeSha256(diskFile);

    final presigned = await _uploadApi.requestPresignedUpload(
      fileName: file.name,
      contentType: contentType,
      sha256: sha256,
      sizeBytes: file.sizeBytes,
    );

    if (!presigned.cached) {
      await _storageUpload.uploadToPresignedUrl(
        uploadUrl: Uri.parse(presigned.uploadUrl),
        file: diskFile,
        contentType: presigned.contentType,
        headers: presigned.headers,
      );
      await _uploadApi.completeUpload(
        sha256: sha256,
        objectKey: presigned.objectKey,
      );
    }

    return UploadResult(
      sha256: sha256,
      objectKey: presigned.objectKey,
      fileName: file.name,
      cached: presigned.cached,
    );
  }
}
