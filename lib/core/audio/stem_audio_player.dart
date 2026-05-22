import 'package:just_audio/just_audio.dart';

/// Reproductor compartido para mix y pistas (Windows requiere [just_audio_windows]).
class StemAudioPlayer {
  StemAudioPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  AudioPlayer get player => _player;

  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> togglePause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
