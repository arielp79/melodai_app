import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodai_app/core/utils/file_hash_calculator.dart';

void main() {
  test('computeSha256 coincide con crypto.sha256 en streaming', () async {
    final tempDir = await Directory.systemTemp.createTemp('melodai_hash_test');
    final file = File('${tempDir.path}/sample.txt');
    await file.writeAsString('melodai');

    final hash = await FileHashCalculator().computeSha256(file);
    final expected = sha256.convert(utf8.encode('melodai')).toString();

    expect(hash, expected);

    await tempDir.delete(recursive: true);
  });
}
