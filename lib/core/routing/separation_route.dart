import 'app_routes.dart';

/// Ruta a separación con parámetros de una subida completada.
String separationRouteForUpload({
  required String sha256,
  required String objectKey,
  required String fileName,
}) {
  return Uri(
    path: AppRoutes.separation,
    queryParameters: {
      'sha256': sha256,
      'objectKey': objectKey,
      'fileName': fileName,
    },
  ).toString();
}
