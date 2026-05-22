import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../viewmodels/mixer_view_model.dart';
import '../widgets/mixer_channel_strip.dart';

class MixerPage extends StatefulWidget {
  const MixerPage({
    super.key,
    required this.viewModel,
    this.jobId,
  });

  final MixerViewModel viewModel;
  final String? jobId;

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> {
  @override
  void initState() {
    super.initState();
    final jobId = widget.jobId;
    if (jobId != null && jobId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.load(jobId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mixer multicanal'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.home),
            ),
          ),
          body: widget.jobId == null
              ? const Center(child: Text('Falta jobId en la ruta.'))
              : _buildBody(context, theme, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, MixerViewModel vm) {
    switch (vm.phase) {
      case MixerPhase.loading:
      case MixerPhase.preparing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                vm.phase == MixerPhase.preparing
                    ? 'Cargando pistas en el motor de audio…'
                    : 'Cargando job…',
              ),
            ],
          ),
        );
      case MixerPhase.error:
        return Center(child: Text(vm.errorMessage ?? 'Error'));
      case MixerPhase.ready:
        final job = vm.job;
        if (job == null) return const SizedBox.shrink();
        return Column(
          children: [
            if (vm.audioError != null)
              MaterialBanner(
                content: Text(vm.audioError!),
                leading: const Icon(Icons.error_outline),
                actions: const [SizedBox.shrink()],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(job.fileName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Varias pistas a la vez · M = mute · S = solo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TransportBar(viewModel: vm),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.volume_up, size: 20),
                      const SizedBox(width: 8),
                      const Text('Master'),
                      Expanded(
                        child: Slider(
                          value: vm.masterVolume,
                          onChanged: vm.hasPlayableChannels
                              ? (v) => vm.setMasterVolume(v)
                              : null,
                        ),
                      ),
                      Text('${(vm.masterVolume * 100).round()}%'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: vm.channels.length,
                itemBuilder: (context, index) {
                  final channel = vm.channels[index];
                  return MixerChannelStrip(
                    channel: channel,
                    enabled: vm.hasPlayableChannels,
                    onVolumeChanged: (v) => vm.setChannelVolume(channel.id, v),
                    onMuteToggled: () => vm.toggleMute(channel.id),
                    onSoloToggled: () => vm.toggleSolo(channel.id),
                  );
                },
              ),
            ),
          ],
        );
      case MixerPhase.idle:
        return const SizedBox.shrink();
    }
  }
}

class _TransportBar extends StatelessWidget {
  const _TransportBar({required this.viewModel});

  final MixerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final canPlay = vm.hasPlayableChannels;

    return Row(
      children: [
        FilledButton.icon(
          onPressed: canPlay ? vm.togglePlayback : null,
          icon: Icon(vm.isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(vm.isPlaying ? 'Pausar mezcla' : 'Reproducir mezcla'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: canPlay ? vm.stopAll : null,
          icon: const Icon(Icons.stop),
          tooltip: 'Detener',
        ),
      ],
    );
  }
}
