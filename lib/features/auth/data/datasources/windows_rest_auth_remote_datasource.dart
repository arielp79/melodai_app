import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/auth/auth_session_store.dart';
import '../../../../core/errors/auth_exception.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';
import 'auth_remote_datasource.dart';

/// Auth por REST en Windows: evita el SDK C++ de Firebase que falla con SSL
/// (unknown-error / internal error) en muchas redes de Windows.
class WindowsRestAuthRemoteDataSource implements AuthRemoteDataSource {
  WindowsRestAuthRemoteDataSource({
    required String apiKey,
    required AuthSessionStore sessionStore,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _sessionStore = sessionStore,
        _http = httpClient ?? http.Client();

  static const _baseUrl = 'https://identitytoolkit.googleapis.com/v1';

  final String _apiKey;
  final AuthSessionStore _sessionStore;
  final http.Client _http;

  @override
  AppUser? get currentUser => _sessionStore.currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _sessionStore.stream;

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: 'accounts:signInWithPassword',
      email: email,
      password: password,
    );
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: 'accounts:signUp',
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    _sessionStore.clear();
  }

  Future<AppUser> _authenticate({
    required String endpoint,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint?key=$_apiKey');
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw _mapRestError(body);
    }

    final map = body as Map<String, dynamic>;
    final user = AppUserModel(
      id: map['localId'] as String,
      email: map['email'] as String?,
    );
    final idToken = map['idToken'] as String?;
    final refreshToken = map['refreshToken'] as String?;
    final expiresIn = int.tryParse('${map['expiresIn']}') ?? 3600;

    if (idToken == null || refreshToken == null) {
      throw const AuthException('No se recibió token de sesión desde Firebase.');
    }

    _sessionStore.setSession(
      user: user,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn,
    );
    return user;
  }

  AuthException _mapRestError(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return const AuthException('Error de autenticación. Inténtalo de nuevo.');
    }
    final error = body['error'];
    if (error is! Map<String, dynamic>) {
      return const AuthException('Error de autenticación. Inténtalo de nuevo.');
    }

    final message = (error['message'] as String?) ?? '';
    final text = switch (message) {
      'EMAIL_NOT_FOUND' => 'No existe una cuenta con este correo.',
      'INVALID_PASSWORD' => 'Contraseña incorrecta.',
      'INVALID_LOGIN_CREDENTIALS' => 'Credenciales inválidas. Revisa correo y contraseña.',
      'EMAIL_EXISTS' => 'Ya existe una cuenta con este correo.',
      'WEAK_PASSWORD' => 'La contraseña es demasiado débil (mínimo 6 caracteres).',
      'INVALID_EMAIL' => 'El correo electrónico no es válido.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' =>
        'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
      'OPERATION_NOT_ALLOWED' =>
        'El registro con correo/contraseña no está habilitado en Firebase Console.',
      _ => 'Error de autenticación: $message',
    };
    return AuthException(text);
  }
}
