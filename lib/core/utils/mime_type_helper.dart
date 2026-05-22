import 'package:mime/mime.dart';

abstract final class MimeTypeHelper {
  static String fromFileName(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }
}
