import 'app_routes.dart';

String mixerRouteForJob(String jobId) {
  return Uri(
    path: AppRoutes.mixer,
    queryParameters: {'jobId': jobId},
  ).toString();
}
