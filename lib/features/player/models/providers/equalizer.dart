import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:y_player/features/player/models/providers/player_provider.dart';

import '../../../../data/audio_source_handler.dart';

part 'equalizer.g.dart';

@HiveType(typeId: 5)
class EqualizerSettings {
  @HiveField(0)
  final bool enabled;
  @HiveField(1)
  final List<double> bandGains;
  @HiveField(2)
  final String presetName;

  const EqualizerSettings({
    required this.enabled,
    required this.bandGains,
    this.presetName = 'Custom',

  });

  factory EqualizerSettings.initial() => const EqualizerSettings(
    enabled: false,
    bandGains: [],
  );

  EqualizerSettings copyWith({
    bool? enabled,
    List<double>? bandGains,
    String? presetName,
  }) {
    return EqualizerSettings(
      enabled: enabled ?? this.enabled,
      bandGains: bandGains ?? this.bandGains,
      presetName: presetName ?? this.presetName,
    );
  }
}
class EqualizerNotifier extends StateNotifier<EqualizerSettings> {
  final AudioSourceHandler _audioHandler;
  final Box<EqualizerSettings> _box;

  EqualizerNotifier(this._audioHandler, this._box)
      : super(_box.get('settings') ?? EqualizerSettings.initial()) {
    _init();
  }

  Future<void> _init() async {
    final params = await _audioHandler.getEqualizerParams();
    if (state.bandGains.length != params.bands.length) {
      state = state.copyWith(
        bandGains: List.filled(params.bands.length, 0.0),
      );
    }
    await _audioHandler.setEqualizerEnabled(state.enabled);
    for (var i = 0; i < state.bandGains.length; i++) {
      await _audioHandler.setBandGain(i, state.bandGains[i]);
    }
  }

  Future<void> toggleEnabled(bool value) async {
    await _audioHandler.setEqualizerEnabled(value);
    state = state.copyWith(enabled: value);
    _persist();
  }

  Future<void> setBandGain(int index, double gain) async {
    await _audioHandler.setBandGain(index, gain);
    final updated = [...state.bandGains];
    updated[index] = gain;
    state = state.copyWith(bandGains: updated, presetName: 'Custom');
    _persist();
  }

  void _persist() {
    _box.put('settings', state);
  }
}

final equalizerProvider =
StateNotifierProvider<EqualizerNotifier, EqualizerSettings>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  final box = Hive.box<EqualizerSettings>('equalizer_box');
  return EqualizerNotifier(audioHandler, box);
});
final equalizerParamsProvider =
FutureProvider<AndroidEqualizerParameters>((ref) async {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.getEqualizerParams();
});