import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/audio/stem_audio_player.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/mixer_route.dart';
import '../../domain/entities/separation_job.dart';
import '../../domain/entities/separation_stem.dart';
import '../viewmodels/separation_view_model.dart';
import '../widgets/stem_playback_controls.dart';

class SeparationPage extends StatefulWidget {
  const SeparationPage({
    super.key,
    required this.viewModel,
    required this.sha256,
    required this.objectKey,
    required this.fileName,
  });

  final SeparationViewModel viewModel;
  final String? sha256;
  final String? objectKey;
  final String? fileName;

  @override
  State<SeparationPage> createState() => _SeparationPageState();
}

class _SeparationPageState extends State<SeparationPage> {
  final StemAudioPlayer _audio = StemAudioPlayer();
  String? _playingId;
  bool _audioLoading = false;
  String? _audioError;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _playUrl(String id, String url) async {
    setState(() {
      _audioLoading = true;
      _audioError = null;
      _playingId = id;
    });
    try {
      await _audio.playUrl(url);
    } catch (e) {
      setState(() => _audioError = 'No se pudo reproducir: $e');
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final sha256 = widget.sha256;
    final objectKey = widget.objectKey;
    if (sha256 != null &&
        sha256.length == 64 &&
        objectKey != null &&
        objectKey.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.start(
          sha256: sha256,
          objectKey: objectKey,
          fileName: widget.fileName ?? 'audio',
        );
      });
    } else {
      widget.viewModel.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missingParams = widget.sha256 == null || widget.objectKey == null;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final job = vm.job;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Separación de pistas'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: vm.isBusy ? null : () => context.go(AppRoutes.home),
            ),
          ),
          body: SafeArea(
            child: missingParams
                ? _MissingParamsBody(onHome: () => context.go(AppRoutes.home))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.fileName ?? 'audio',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fase 1 — Voz, bajo, batería, guitarra y piano (HTDemucs)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (vm.errorMessage != null) ...[
                          MaterialBanner(
                            content: Text(vm.errorMessage!),
                            leading: const Icon(Icons.error_outline),
                            backgroundColor: theme.colorScheme.errorContainer,
                            actions: const [SizedBox.shrink()],
                          ),
                          const SizedBox(height: 16),
                        ],
                        _StatusCard(phase: vm.phase, job: job),
                        if (vm.phase == SeparationPhase.completed &&
                            job != null) ...[
                          const SizedBox(height: 24),
                          StemPlaybackControls(
                            player: _audio.player,
                            playingId: _playingId,
                            loading: _audioLoading,
                            error: _audioError,
                            sourceAudioUrl: job.sourceAudioUrl,
                            anyStemPlayable: job.stems.any(_stemHasAudio),
                            onPlaySource: job.sourceAudioUrl == null
                                ? () {}
                                : () => _playUrl('source', job.sourceAudioUrl!),
                            onTogglePause: () async {
                              await _audio.togglePause();
                              setState(() {});
                            },
                            onStop: () async {
                              await _audio.stop();
                              setState(() => _playingId = null);
                            },
                          ),
                        ],
                        if (job != null && job.stems.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Pistas', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ...job.stems.map(
                            (stem) => Card(
                              child: ListTile(
                                leading: Icon(
                                  _iconForStem(stem.id),
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(stem.label),
                                subtitle: Text(
                                  _stemHasAudio(stem)
                                      ? 'Lista para reproducir'
                                      : stem.objectKey,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (stem.simulated)
                                      const Chip(
                                        label: Text('stub'),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    IconButton(
                                      onPressed: !_stemHasAudio(stem) ||
                                              _audioLoading
                                          ? null
                                          : () => _playUrl(
                                                stem.id,
                                                stem.downloadUrl!,
                                              ),
                                      icon: Icon(
                                        _playingId == stem.id &&
                                                _audio.player.playing
                                            ? Icons.volume_up
                                            : Icons.play_arrow,
                                      ),
                                      tooltip: _stemHasAudio(stem)
                                          ? 'Reproducir pista'
                                          : 'Sin audio (stub)',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (vm.phase == SeparationPhase.completed) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.go(
                                mixerRouteForJob(job.jobId),
                              ),
                              icon: const Icon(Icons.tune),
                              label: const Text('Abrir mixer'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.cached
                                  ? 'Resultado recuperado de caché (mismo SHA-256).'
                                  : 'Abre el mixer para escuchar varias pistas a la vez (M/S y faders).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  bool _stemHasAudio(SeparationStem stem) =>
      stem.downloadUrl != null && stem.downloadUrl!.isNotEmpty;

  IconData _iconForStem(String id) {
    return switch (id) {
      'vocals' => Icons.mic_outlined,
      'bass' => Icons.music_note_outlined,
      'drums' => Icons.album_outlined,
      'guitar' => Icons.queue_music_outlined,
      'piano' => Icons.piano_outlined,
      _ => Icons.audiotrack_outlined,
    };
  }
}

class _MissingParamsBody extends StatelessWidget {
  const _MissingParamsBody({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Sube un audio primero para iniciar la separación.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onHome,
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.phase, required this.job});

  final SeparationPhase phase;
  final SeparationJob? job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, title, subtitle) = switch (phase) {
      SeparationPhase.idle => (
          Icons.hourglass_empty,
          'Preparando…',
          null,
        ),
      SeparationPhase.starting => (
          Icons.play_circle_outline,
          'Creando job…',
          null,
        ),
      SeparationPhase.polling => job?.status == SeparationJobStatus.queued
          ? (
              Icons.schedule,
              'En cola',
              'Esperando al worker Python. Si lleva mucho rato, arranca:\n'
                  'cd worker → .venv\\Scripts\\activate → python main.py',
            )
          : (
              Icons.autorenew,
              'Procesando (HTDemucs)',
              'En CPU puede tardar 10–40 min según la canción',
            ),
      SeparationPhase.completed => (
          Icons.check_circle_outline,
          job?.cached == true ? 'Completado (caché)' : 'Completado',
          '${job?.stems.length ?? 0} pistas',
        ),
      SeparationPhase.failed => (
          Icons.error_outline,
          'Error',
          job?.error,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (phase == SeparationPhase.polling && job != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: job!.status == SeparationJobStatus.queued && job!.progress == 0
                    ? null
                    : job!.progress / 100,
              ),
              const SizedBox(height: 8),
              Text(
                job!.status == SeparationJobStatus.queued && job!.progress == 0
                    ? 'En cola — 0 %'
                    : '${job!.progress} %',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
