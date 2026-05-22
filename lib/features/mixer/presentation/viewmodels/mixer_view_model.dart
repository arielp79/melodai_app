import 'package:flutter/foundation.dart';

import '../../../../core/audio/multichannel_mixer_engine.dart';
import '../../../separation/domain/entities/separation_job.dart';
import '../../../separation/domain/usecases/get_separation_job.dart';
import '../../../../core/errors/separation_exception.dart';
import '../../domain/entities/mixer_channel_state.dart';

enum MixerPhase { idle, loading, preparing, ready, error }

class MixerViewModel extends ChangeNotifier {
  MixerViewModel({required GetSeparationJob getSeparationJob})
      : _getSeparationJob = getSeparationJob;

  final GetSeparationJob _getSeparationJob;
  final MultichannelMixerEngine engine = MultichannelMixerEngine();

  MixerPhase phase = MixerPhase.idle;
  SeparationJob? job;
  List<MixerChannelState> channels = [];
  String? errorMessage;
  String? audioError;
  double masterVolume = 1.0;
  bool isPlaying = false;

  bool get hasPlayableChannels => channels.any((c) => c.isPlayable);

  Future<void> load(String jobId) async {
    await engine.dispose();
    phase = MixerPhase.loading;
    errorMessage = null;
    audioError = null;
    job = null;
    channels = [];
    isPlaying = false;
    notifyListeners();

    try {
      final loaded = await _getSeparationJob(jobId);
      job = loaded;
      channels = _buildChannels(loaded);
      phase = MixerPhase.preparing;
      notifyListeners();

      await _prepareEngine();
      phase = MixerPhase.ready;
    } on SeparationException catch (e) {
      phase = MixerPhase.error;
      errorMessage = e.message;
    } catch (e) {
      phase = MixerPhase.error;
      errorMessage = 'No se pudo cargar el mixer: $e';
    } finally {
      notifyListeners();
    }
  }

  List<MixerChannelState> _buildChannels(SeparationJob loaded) {
    final list = <MixerChannelState>[];

    final sourceUrl = loaded.sourceAudioUrl;
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      list.add(
        MixerChannelState(
          id: 'source',
          label: 'Mix original',
          downloadUrl: sourceUrl,
          isLoaded: true,
          volume: 0.75,
        ),
      );
    }

    list.addAll(loaded.stems.map(MixerChannelState.fromStem));
    return list;
  }

  Future<void> _prepareEngine() async {
    final sources = <({String id, String url})>[];
    final updated = <MixerChannelState>[];

    for (final channel in channels) {
      final url = channel.downloadUrl;
      if (url == null || url.isEmpty) {
        updated.add(
          channel.copyWith(
            isLoaded: false,
            loadError: 'Sin audio en el bucket',
          ),
        );
        continue;
      }
      sources.add((id: channel.id, url: url));
      updated.add(channel.copyWith(isLoaded: true, loadError: null));
    }

    channels = updated;
    notifyListeners();

    if (sources.isEmpty) {
      audioError = 'Ninguna pista tiene audio. Ejecuta HTDemucs en el worker.';
      return;
    }

    try {
      await engine.prepare(sources);
      channels = channels
          .map(
            (c) => c.copyWith(
              isLoaded: engine.hasChannel(c.id),
              loadError: engine.hasChannel(c.id)
                  ? null
                  : (c.downloadUrl != null ? 'No se pudo cargar el audio' : null),
            ),
          )
          .toList();
      await _syncEngineFromChannels();
      audioError = engine.hasChannels
          ? null
          : 'Ninguna pista se pudo cargar en el motor de audio.';
    } catch (e) {
      audioError = 'Error al preparar la mezcla: $e';
    }
  }

  List<({String id, double volume, bool muted, bool solo})> _channelMixStates() {
    return channels
        .map(
          (c) => (
            id: c.id,
            volume: c.volume,
            muted: c.muted,
            solo: c.solo,
          ),
        )
        .toList();
  }

  Future<void> _syncEngineFromChannels() async {
    engine.setMasterVolume(masterVolume);
    await engine.applyMixState(_channelMixStates());
    isPlaying = engine.isPlaying;
  }

  Future<void> togglePlayback() async {
    try {
      await engine.togglePlayPause();
      isPlaying = engine.isPlaying;
      audioError = null;
    } catch (e) {
      audioError = 'No se pudo reproducir: $e';
    }
    notifyListeners();
  }

  Future<void> stopAll() async {
    try {
      await engine.stop();
      isPlaying = false;
      audioError = null;
    } catch (e) {
      audioError = 'No se pudo detener: $e';
    }
    notifyListeners();
  }

  Future<void> setChannelVolume(String id, double value) async {
    final index = channels.indexWhere((c) => c.id == id);
    if (index < 0) return;
    channels[index] = channels[index].copyWith(volume: value);
    await _syncEngineFromChannels();
    notifyListeners();
  }

  Future<void> toggleMute(String id) async {
    final index = channels.indexWhere((c) => c.id == id);
    if (index < 0) return;
    channels[index] = channels[index].copyWith(
      muted: !channels[index].muted,
    );
    await _syncEngineFromChannels();
    notifyListeners();
  }

  Future<void> toggleSolo(String id) async {
    final index = channels.indexWhere((c) => c.id == id);
    if (index < 0) return;
    channels[index] = channels[index].copyWith(
      solo: !channels[index].solo,
    );
    await _syncEngineFromChannels();
    notifyListeners();
  }

  Future<void> setMasterVolume(double value) async {
    masterVolume = value.clamp(0.0, 1.0);
    await _syncEngineFromChannels();
    notifyListeners();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }
}
