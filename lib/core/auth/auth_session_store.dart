import 'dart:async';

import '../../features/auth/domain/entities/app_user.dart';

/// Sesión en memoria para plataformas que autentican vía REST (p. ej. Windows).
class AuthSessionStore {
  AppUser? _user;
  String? _idToken;
  String? _refreshToken;
  DateTime? _idTokenExpiresAt;

  final _controller = StreamController<AppUser?>.broadcast();

  AppUser? get currentUser => _user;

  String? get idToken => _idToken;

  String? get refreshToken => _refreshToken;

  bool get isIdTokenValid {
    final expiresAt = _idTokenExpiresAt;
    if (_idToken == null || expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt);
  }

  Stream<AppUser?> get stream => _controller.stream;

  void setSession({
    required AppUser user,
    required String idToken,
    required String refreshToken,
    int expiresInSeconds = 3600,
  }) {
    _user = user;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _idTokenExpiresAt = _expiryFromNow(expiresInSeconds);
    _controller.add(_user);
  }

  void updateTokens({
    required String idToken,
    required String refreshToken,
    int expiresInSeconds = 3600,
  }) {
    _idToken = idToken;
    _refreshToken = refreshToken;
    _idTokenExpiresAt = _expiryFromNow(expiresInSeconds);
  }

  void clear() {
    _user = null;
    _idToken = null;
    _refreshToken = null;
    _idTokenExpiresAt = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();

  DateTime _expiryFromNow(int expiresInSeconds) {
    const bufferSeconds = 60;
    final safeSeconds = expiresInSeconds > bufferSeconds
        ? expiresInSeconds - bufferSeconds
        : expiresInSeconds;
    return DateTime.now().add(Duration(seconds: safeSeconds));
  }
}
