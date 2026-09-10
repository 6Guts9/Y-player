// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equalizer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EqualizerSettingsAdapter extends TypeAdapter<EqualizerSettings> {
  @override
  final int typeId = 5;

  @override
  EqualizerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EqualizerSettings(
      enabled: fields[0] as bool,
      bandGains: (fields[1] as List).cast<double>(),
      presetName: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EqualizerSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.bandGains)
      ..writeByte(2)
      ..write(obj.presetName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
