import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session_store.dart';

/// Renueva el ID token de Firebase en Windows (REST) cuando expira.
class FirebaseSessionTokenProvider {
  FirebaseSessionTokenProvider({
    required String apiKey,
    required AuthSessionStore sessionStore,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _sessionStore = sessionStore,
        _http = httpClient ?? http.Client();

  static const _tokenUrl = 'https://securetoken.googleapis.com/v1/token';

  final String _apiKey;
  final AuthSessionStore _sessionStore;
  final http.Client _http;

  Future<String> getIdToken() async {
    final cached = _sessionStore.idToken;
    if (cached != null && _sessionStore.isIdTokenValid) {
      return cached;
    }
    return _refreshIdToken();
  }

  Future<String> _refreshIdToken() async {
    final refreshToken = _sessionStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError(
        'Sesión expirada. Cierra sesión e inicia de nuevo en la app.',
      );
    }

    final uri = Uri.parse('$_tokenUrl?key=$_apiKey');
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body:
          'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(refreshToken)}',
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      _sessionStore.clear();
      final message = body is Map ? '${body['error'] ?? body}' : '$body';
      throw StateError(
        'Sesión expirada ($message). Vuelve a iniciar sesión.',
      );
    }

    final map = body as Map<String, dynamic>;
    final idToken = map['id_token'] as String?;
    final newRefresh = map['refresh_token'] as String? ?? refreshToken;
    final expiresIn = int.tryParse('${map['expires_in']}') ?? 3600;

    if (idToken == null) {
      throw StateError('No se pudo renovar el token de sesión.');
    }

    _sessionStore.updateTokens(
      idToken: idToken,
      refreshToken: newRefresh,
      expiresInSeconds: expiresIn,
    );
    return idToken;
  }
}
