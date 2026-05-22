import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/auth_exception.dart';

AuthException mapFirebaseAuthException(FirebaseAuthException exception) {
  final message = switch (exception.code) {
    'invalid-email' => 'El correo electrónico no es válido.',
    'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
    'user-not-found' => 'No existe una cuenta con este correo.',
    'wrong-password' => 'Contraseña incorrecta.',
    'email-already-in-use' => 'Ya existe una cuenta con este correo.',
    'weak-password' => 'La contraseña es demasiado débil (mínimo 6 caracteres).',
    'invalid-credential' => 'Credenciales inválidas. Revisa correo y contraseña.',
    'too-many-requests' => 'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
    'network-request-failed' =>
      'Error de red o certificado SSL. En Windows: Opciones de Internet → Avanzadas → desactiva la comprobación de revocación de certificados.',
    'operation-not-allowed' =>
      'El registro con correo/contraseña no está habilitado. Actívalo en Firebase Console → Authentication → Sign-in method.',
    'internal-error' =>
      'Error interno de Firebase. Suele ser red o SSL en Windows; revisa la terminal (flutter run) para más detalle.',
    'unknown-error' =>
      'Error de red o certificado SSL en Windows. Reinicia la app (tecla R). Si persiste: Opciones de Internet → Avanzadas → desactiva comprobación de revocación de certificados.',
    _ => 'Error de autenticación (${exception.code}): ${exception.message ?? 'sin detalle'}',
  };

  return AuthException(message);
}
