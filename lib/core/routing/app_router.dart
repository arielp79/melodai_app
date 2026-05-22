import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';



import '../../features/auth/domain/repositories/auth_repository.dart';

import '../../features/auth/presentation/pages/login_page.dart';

import '../../features/home/presentation/pages/home_page.dart';

import '../../features/upload/presentation/pages/upload_page.dart';
import '../../features/separation/presentation/pages/separation_page.dart';
import '../../features/mixer/presentation/pages/mixer_page.dart';

import '../di/injection.dart' as di;

import 'app_routes.dart';

import 'go_router_refresh_stream.dart';

import 'route_placeholders.dart';



/// Configuración central de navegación con redirección según sesión.

class AppRouter {

  AppRouter({AuthRepository? authRepository})

      : _authRepository = authRepository ?? di.authRepository {

    router = GoRouter(

      initialLocation: AppRoutes.login,

      refreshListenable: GoRouterRefreshStream(_authRepository.authStateChanges),

      redirect: _redirect,

      routes: _routes,

    );

  }



  final AuthRepository _authRepository;

  late final GoRouter router;



  String? _redirect(BuildContext context, GoRouterState state) {

    final isLoggedIn = _authRepository.currentUser != null;

    final location = state.matchedLocation;

    final isLoginRoute = location == AppRoutes.login;



    if (!isLoggedIn) {

      return isLoginRoute ? null : AppRoutes.login;

    }



    if (isLoginRoute) {

      return AppRoutes.home;

    }



    return null;

  }



  List<RouteBase> get _routes => [

        GoRoute(

          path: AppRoutes.login,

          builder: (context, state) => LoginPage(viewModel: di.authViewModel),

        ),

        GoRoute(

          path: AppRoutes.home,

          builder: (context, state) => HomePage(viewModel: di.authViewModel),

        ),

        GoRoute(

          path: AppRoutes.upload,

          builder: (context, state) => UploadPage(viewModel: di.uploadViewModel),

        ),

        GoRoute(

          path: AppRoutes.separation,

          builder: (context, state) {
            final query = state.uri.queryParameters;
            return SeparationPage(
              viewModel: di.separationViewModel,
              sha256: query['sha256'],
              objectKey: query['objectKey'],
              fileName: query['fileName'],
            );
          },

        ),

        GoRoute(

          path: AppRoutes.mixer,

          builder: (context, state) {
            final jobId = state.uri.queryParameters['jobId'];
            return MixerPage(
              viewModel: di.mixerViewModel,
              jobId: jobId,
            );
          },

        ),

        GoRoute(

          path: AppRoutes.export,

          builder: (context, state) =>

              const RoutePlaceholder(label: 'Export (placeholder)'),

        ),

      ];

}

