import '../../../separation/domain/entities/separation_stem.dart';

class MixerChannelState {
  const MixerChannelState({
    required this.id,
    required this.label,
    required this.downloadUrl,
    this.volume = 0.85,
    this.muted = false,
    this.solo = false,
    this.isLoaded = false,
    this.loadError,
  });

  factory MixerChannelState.fromStem(SeparationStem stem) {
    return MixerChannelState(
      id: stem.id,
      label: stem.label,
      downloadUrl: stem.downloadUrl,
    );
  }

  final String id;
  final String label;
  final String? downloadUrl;
  final double volume;
  final bool muted;
  final bool solo;
  final bool isLoaded;
  final String? loadError;

  bool get isPlayable =>
      downloadUrl != null && downloadUrl!.isNotEmpty && isLoaded;

  MixerChannelState copyWith({
    double? volume,
    bool? muted,
    bool? solo,
    bool? isLoaded,
    String? loadError,
  }) {
    return MixerChannelState(
      id: id,
      label: label,
      downloadUrl: downloadUrl,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      solo: solo ?? this.solo,
      isLoaded: isLoaded ?? this.isLoaded,
      loadError: loadError ?? this.loadError,
    );
  }
}
