import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifica a [GoRouter] cuando cambia el stream (p. ej. authStateChanges).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
