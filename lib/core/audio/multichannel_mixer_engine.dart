import 'package:just_audio/just_audio.dart';

class _ChannelRuntime {
  _ChannelRuntime({
    required this.id,
    required this.player,
    required this.volume,
    required this.muted,
    required this.solo,
  });

  final String id;
  final AudioPlayer player;
  double volume;
  bool muted;
  bool solo;
}

/// Motor de mezcla: un [AudioPlayer] por pista, volúmenes/mute/solo en tiempo real.
class MultichannelMixerEngine {
  final Map<String, _ChannelRuntime> _channels = {};
  double _masterVolume = 1.0;
  bool _playing = false;

  bool get isPlaying => _playing;
  bool get hasChannels => _channels.isNotEmpty;

  bool hasChannel(String id) => _channels.containsKey(id);

  bool get _anySolo => _channels.values.any((c) => c.solo);

  double _effectiveVolume(_ChannelRuntime channel) {
    if (_anySolo) {
      if (!channel.solo) return 0;
    } else if (channel.muted) {
      return 0;
    }
    return (channel.volume * _masterVolume).clamp(0.0, 1.0);
  }

  Future<void> _applyVolumes() async {
    await Future.wait(
      _channels.values.map((c) => c.player.setVolume(_effectiveVolume(c))),
    );
  }

  Future<void> prepare(
    List<({String id, String url})> sources,
  ) async {
    await dispose();
    for (final source in sources) {
      final player = AudioPlayer();
      try {
        await player.setUrl(source.url);
        await player.setVolume(0);
        _channels[source.id] = _ChannelRuntime(
          id: source.id,
          player: player,
          volume: 0.85,
          muted: false,
          solo: false,
        );
      } catch (_) {
        await player.dispose();
      }
    }
  }

  void syncChannelState({
    required String id,
    required double volume,
    required bool muted,
    required bool solo,
  }) {
    final channel = _channels[id];
    if (channel == null) return;
    channel.volume = volume.clamp(0.0, 1.0);
    channel.muted = muted;
    channel.solo = solo;
  }

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
  }

  Future<void> play() async {
    if (_channels.isEmpty) return;
    await _applyVolumes();
    final audible = _channels.values.where((c) => _effectiveVolume(c) > 0);
    await Future.wait(audible.map((c) => c.player.play()));
    _playing = true;
  }

  Future<void> pause() async {
    await Future.wait(_channels.values.map((c) => c.player.pause()));
    _playing = false;
  }

  Future<void> stop() async {
    await Future.wait(_channels.values.map((c) => c.player.stop()));
    _playing = false;
  }

  Future<void> togglePlayPause() async {
    if (_playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> applyMixState(
    List<({String id, double volume, bool muted, bool solo})> states,
  ) async {
    for (final state in states) {
      syncChannelState(
        id: state.id,
        volume: state.volume,
        muted: state.muted,
        solo: state.solo,
      );
    }
    await _applyVolumes();
    if (_playing) {
      final audible = _channels.values.where((c) => _effectiveVolume(c) > 0);
      final silent = _channels.values.where((c) => _effectiveVolume(c) == 0);
      await Future.wait(silent.map((c) => c.player.pause()));
      await Future.wait(audible.map((c) => c.player.play()));
    }
  }

  Future<void> dispose() async {
    _playing = false;
    final players = _channels.values.map((c) => c.player).toList();
    _channels.clear();
    await Future.wait(players.map((p) => p.dispose()));
  }
}
