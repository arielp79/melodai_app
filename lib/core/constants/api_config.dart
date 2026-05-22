/// URL base del orquestador Node.js (presigned URLs, jobs, etc.).
///
/// - Windows / iOS simulador / desktop: `http://127.0.0.1:3000`
/// - Emulador Android: `http://10.0.2.2:3000`
/// - Dispositivo físico: IP de tu PC, p. ej. `http://192.168.1.10:3000`
///
/// Sobrescribe en run:
/// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
}
