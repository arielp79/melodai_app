import 'app_routes.dart';

String exportRouteForJob(String jobId) {
  return Uri(
    path: AppRoutes.export,
    queryParameters: {'jobId': jobId},
  ).toString();
}
