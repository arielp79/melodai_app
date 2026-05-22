import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// Shell inicial tras autenticación. Las features se enlazarán aquí más adelante.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final email = authRepository.currentUser?.email ?? 'Usuario';

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('MelodAI'),
            actions: [
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  onPressed: viewModel.logout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sesión activa',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.upload),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Subir canción'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.upload),
                    icon: const Icon(Icons.graphic_eq),
                    label: const Text('Separación de pistas'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tras subir un audio, inicia la separación Fase 1. Mixer próximamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
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
