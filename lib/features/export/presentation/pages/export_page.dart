import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../viewmodels/export_view_model.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({
    super.key,
    required this.viewModel,
    this.jobId,
  });

  final ExportViewModel viewModel;
  final String? jobId;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
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
    final missingJobId = widget.jobId == null || widget.jobId!.isEmpty;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final job = vm.job;
        final busy = vm.phase == ExportPhase.loading ||
            vm.phase == ExportPhase.exporting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Exportar pistas'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: busy ? null : () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: missingJobId
                ? _MessageBody(
                    message: 'Falta el jobId. Abre exportar desde la pantalla de separación.',
                    onHome: () => context.go(AppRoutes.home),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (job != null) ...[
                          Text(
                            job.fileName,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${vm.playableCount} de ${job.stems.length} pistas con audio',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (vm.errorMessage != null)
                          MaterialBanner(
                            content: Text(vm.errorMessage!),
                            leading: const Icon(Icons.error_outline),
                            backgroundColor: theme.colorScheme.errorContainer,
                            actions: const [SizedBox.shrink()],
                          ),
                        if (vm.successMessage != null) ...[
                          MaterialBanner(
                            content: Text(vm.successMessage!),
                            leading: const Icon(Icons.check_circle_outline),
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            actions: const [SizedBox.shrink()],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (vm.phase == ExportPhase.loading)
                          const Center(child: CircularProgressIndicator())
                        else if (vm.phase == ExportPhase.error && job == null)
                          _MessageBody(
                            message: vm.errorMessage ?? 'Error',
                            onHome: () => context.go(AppRoutes.home),
                          )
                        else ...[
                          FilledButton.icon(
                            onPressed: vm.canExport && !busy
                                ? vm.exportZip
                                : null,
                            icon: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.folder_zip_outlined),
                            label: const Text('Descargar todo (ZIP)'),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Pistas individuales',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              children: job!.stems.map((stem) {
                                final hasAudio = vm.playableCount > 0 &&
                                    stem.downloadUrl != null &&
                                    stem.downloadUrl!.isNotEmpty;
                                return Card(
                                  child: ListTile(
                                    title: Text(stem.label),
                                    subtitle: Text(
                                      hasAudio
                                          ? stem.id
                                          : 'Sin audio (stub)',
                                    ),
                                    trailing: IconButton(
                                      onPressed: hasAudio && !busy
                                          ? () => vm.exportOne(stem)
                                          : null,
                                      icon: const Icon(Icons.download_outlined),
                                      tooltip: 'Guardar .wav',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, required this.onHome});

  final String message;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onHome, child: const Text('Ir al inicio')),
          ],
        ),
      ),
    );
  }
}
