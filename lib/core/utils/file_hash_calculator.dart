import 'dart:io';

import 'package:crypto/crypto.dart';

/// Calcula SHA-256 del archivo en streaming (adecuado para archivos grandes).
class FileHashCalculator {
  Future<String> computeSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
