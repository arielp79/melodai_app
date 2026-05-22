import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/separation_route.dart';
import '../viewmodels/upload_view_model.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key, required this.viewModel});

  final UploadViewModel viewModel;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final file = vm.selectedFile;
        final result = vm.lastResult;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Subir audio'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: vm.isBusy ? null : () => context.go(AppRoutes.home),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Formatos: MP3, WAV, FLAC, M4A',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El archivo se sube directo al bucket con URL firmada. '
                    'El backend solo entrega el enlace seguro.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (vm.errorMessage != null) ...[
                    MaterialBanner(
                      content: Text(vm.errorMessage!),
                      leading: const Icon(Icons.error_outline),
                      backgroundColor: theme.colorScheme.errorContainer,
                      actions: [
                        TextButton(
                          onPressed: vm.clearError,
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: vm.isBusy ? null : vm.pickFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      file == null ? 'Seleccionar archivo' : 'Cambiar archivo',
                    ),
                  ),
                  if (file != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Tamaño: ${_formatBytes(file.sizeBytes)}'),
                            Text('Formato: .${file.extension}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (vm.isBusy) ...[
                    const Center(child: CircularProgressIndicator()),
                    if (vm.statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        vm.statusMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ] else ...[
                    FilledButton.icon(
                      onPressed: file == null ? null : vm.uploadSelected,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Subir al servidor'),
                    ),
                  ],
                  if (vm.phase == UploadPhase.success && result != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  result.cached
                                      ? Icons.cached
                                      : Icons.check_circle_outline,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  result.cached
                                      ? 'Resultado en caché'
                                      : 'Subida exitosa',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SHA-256',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            SelectableText(
                              result.sha256,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Object key: ${result.objectKey}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.go(
                                separationRouteForUpload(
                                  sha256: result.sha256,
                                  objectKey: result.objectKey,
                                  fileName: result.fileName,
                                ),
                              ),
                              icon: const Icon(Icons.graphic_eq),
                              label: const Text('Separar pistas'),
                            ),
                          ],
                        ),
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
