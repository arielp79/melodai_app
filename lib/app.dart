import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class MelodaiApp extends StatelessWidget {
  MelodaiApp({super.key, AppRouter? appRouter})
      : _appRouter = appRouter ?? AppRouter();

  final AppRouter _appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MelodAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _appRouter.router,
    );
  }
}
