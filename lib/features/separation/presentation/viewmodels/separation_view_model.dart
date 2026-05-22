import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/separation_job.dart';
import '../../domain/usecases/create_separation_job.dart';
import '../../domain/usecases/get_separation_job.dart';
import '../../../../core/errors/separation_exception.dart';

enum SeparationPhase { idle, starting, polling, completed, failed }

class SeparationViewModel extends ChangeNotifier {
  SeparationViewModel({
    required CreateSeparationJob createJob,
    required GetSeparationJob getJob,
    this.pollInterval = const Duration(seconds: 2),
  })  : _createJob = createJob,
        _getJob = getJob;

  final CreateSeparationJob _createJob;
  final GetSeparationJob _getJob;
  final Duration pollInterval;

  SeparationPhase phase = SeparationPhase.idle;
  SeparationJob? job;
  String? errorMessage;
  Timer? _pollTimer;

  String? _lastSha256;
  String? _lastObjectKey;
  String? _lastFileName;
  bool _retryingAfter404 = false;

  bool get isBusy =>
      phase == SeparationPhase.starting || phase == SeparationPhase.polling;

  void reset() {
    _stopPolling();
    phase = SeparationPhase.idle;
    job = null;
    errorMessage = null;
    _lastSha256 = null;
    _lastObjectKey = null;
    _lastFileName = null;
    _retryingAfter404 = false;
    notifyListeners();
  }

  Future<void> start({
    required String sha256,
    required String objectKey,
    required String fileName,
  }) async {
    _lastSha256 = sha256;
    _lastObjectKey = objectKey;
    _lastFileName = fileName;
    _retryingAfter404 = false;
    _stopPolling();
    phase = SeparationPhase.starting;
    errorMessage = null;
    job = null;
    notifyListeners();

    try {
      job = await _createJob(
        sha256: sha256,
        objectKey: objectKey,
        fileName: fileName,
      );
      if (job!.status.isTerminal) {
        phase = job!.status == SeparationJobStatus.completed
            ? SeparationPhase.completed
            : SeparationPhase.failed;
        if (job!.status == SeparationJobStatus.failed) {
          errorMessage = job!.error ?? 'La separación falló.';
        }
      } else {
        phase = SeparationPhase.polling;
        _startPolling(job!.jobId);
      }
    } on SeparationException catch (e) {
      phase = SeparationPhase.failed;
      errorMessage = e.message;
    } catch (e) {
      phase = SeparationPhase.failed;
      errorMessage = 'Error al iniciar separación: $e';
    } finally {
      notifyListeners();
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce(jobId));
    _pollOnce(jobId);
  }

  Future<void> _pollOnce(String jobId) async {
    try {
      final updated = await _getJob(jobId);
      job = updated;
      if (updated.status.isTerminal) {
        _stopPolling();
        phase = updated.status == SeparationJobStatus.completed
            ? SeparationPhase.completed
            : SeparationPhase.failed;
        if (updated.status == SeparationJobStatus.failed) {
          errorMessage = updated.error ?? 'La separación falló.';
        }
      }
      notifyListeners();
    } on SeparationException catch (e) {
      final notFound = _isJobNotFoundError(e.message);
      if (notFound &&
          !_retryingAfter404 &&
          _lastSha256 != null &&
          _lastObjectKey != null) {
        _retryingAfter404 = true;
        _stopPolling();
        await start(
          sha256: _lastSha256!,
          objectKey: _lastObjectKey!,
          fileName: _lastFileName ?? 'audio',
        );
        return;
      }
      _stopPolling();
      phase = SeparationPhase.failed;
      errorMessage = notFound
          ? 'El job expiró (el backend se reinició). Vuelve a pulsar «Separar pistas» desde la subida.'
          : e.message;
      notifyListeners();
    }
  }

  bool _isJobNotFoundError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('no encontrado') || message.contains('404');
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
