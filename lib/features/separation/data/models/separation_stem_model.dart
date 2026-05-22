import '../../domain/entities/separation_stem.dart';

class SeparationStemModel extends SeparationStem {
  const SeparationStemModel({
    required super.id,
    required super.label,
    required super.objectKey,
    required super.phase,
    super.simulated,
    super.downloadUrl,
  });

  factory SeparationStemModel.fromJson(Map<String, dynamic> json) {
    return SeparationStemModel(
      id: json['id'] as String,
      label: json['label'] as String,
      objectKey: json['objectKey'] as String,
      phase: json['phase'] as int? ?? 1,
      simulated: json['simulated'] as bool? ?? false,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}
