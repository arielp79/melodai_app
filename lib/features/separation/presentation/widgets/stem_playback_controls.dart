import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Controles de reproducción compartidos (mix + pistas con URL).
class StemPlaybackControls extends StatelessWidget {
  const StemPlaybackControls({
    super.key,
    required this.player,
    required this.playingId,
    required this.loading,
    required this.error,
    required this.onPlaySource,
    required this.onTogglePause,
    required this.onStop,
    required this.sourceAudioUrl,
    required this.anyStemPlayable,
  });

  final AudioPlayer player;
  final String? playingId;
  final bool loading;
  final String? error;
  final VoidCallback onPlaySource;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;
  final String? sourceAudioUrl;
  final bool anyStemPlayable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!anyStemPlayable) ...[
          MaterialBanner(
            content: const Text(
              'Las pistas separadas son simuladas (stub): aún no hay .wav en el bucket. '
              'Escucha el mix original abajo. Tras HTDemucs, cada pista tendrá botón play.',
            ),
            leading: const Icon(Icons.info_outline),
            actions: const [SizedBox.shrink()],
          ),
          const SizedBox(height: 12),
        ],
        if (sourceAudioUrl != null) ...[
          Text('Reproducir', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loading && playingId == 'source' ? null : onPlaySource,
            icon: Icon(
              playingId == 'source' && player.playing
                  ? Icons.music_note
                  : Icons.play_arrow,
            ),
            label: const Text('Mix original (canción subida)'),
          ),
          const SizedBox(height: 8),
        ],
        if (playingId != null) ...[
          Row(
            children: [
              IconButton(
                onPressed: loading ? null : onTogglePause,
                icon: Icon(player.playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                onPressed: loading ? null : onStop,
                icon: const Icon(Icons.stop),
              ),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = player.duration ?? Duration.zero;
                    return Text(
                      '${_format(pos)} / ${_format(dur)}',
                      style: theme.textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
