import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum AudioSourceType {local,remote}
///enum is a fixed named set of values
///instead of representing it wiht a string or an int we get a real type that the compiler checks
class Track {
  final String id;

  final String title;

  final String artist;

  final String? album;

  final String uri;

  final AudioSourceType sourceType;
  final String? artworkUri;
  final Duration duration;
  final DateTime dateAdded;
  final int playCount;
  final bool isFavorite;

  const Track({
// 11 element
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.sourceType,
    required this.dateAdded,
    this.duration = Duration.zero,
    this.artworkUri,
    this.album,
    this.playCount = 0,
    this.isFavorite = false,


  });
/// copyWith is used to update immutable objects (an object whose state cannot be changed after it is created)
  ///  Flutter relies heavily on immutable data classes and widgets , copyWith returns a brand new instance containing the updated properties alongside the original
  Track copyWith({
    String? title,
    String? artist,
    String? album,
    String? artworkUri,
    Duration? duration,
    int? playCount,
    bool? isFavorite,

  }) {
  return Track(
      id: id,
      uri: uri,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      sourceType: sourceType,
      dateAdded: dateAdded,
      artworkUri: artworkUri ?? this.artworkUri,
      duration: duration ?? this.duration,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,

  );}
  @override
  bool operator ==(Object other) => other is Track && other.id == id;
  @override
  int get hashCode => id.hashCode;
  ///The == and hashCode override by default
  /// Dart compares two objects by whether they're literally the same object in memory
  /// we want two Tracks with the same id to be treated as "the same track" even if one is a slightly newer copy for examole in case of copyWith bumped playCount
  /// overriding "==" lets you write list.contains(track) or trackA == trackB and get sensible results
  /// hashCode has to be overridden alongside it
  ///it's a Dart rule: if two objects are == equal ,they must produce the same hashcode or things like Set and Map lookups break.
  factory Track.fromLibrary(
    SongModel model, {
    int playCount = 0,
    bool isFavorite = false,
    String? customTitle,
    String? customArtist,
    String? customArtwork,
  }) {
    final rawArtist = model.artist?.trim();
    final modelArtistValid = rawArtist != null &&
        rawArtist.isNotEmpty &&
        rawArtist != '<unknown>' &&
        rawArtist.toLowerCase() != 'unknown artist';

    final rawTitle = model.title.trim();
    final modelTitleValid = rawTitle.isNotEmpty &&
        rawTitle != '<unknown>' &&
        !rawTitle.startsWith('AUD-') &&
        !rawTitle.startsWith('VID-');

    return Track(
      id: model.id.toString(),
      title: (customTitle != null && customTitle.isNotEmpty)
          ? customTitle
          : (modelTitleValid ? model.title : model.displayNameWOExt),
      artist: (customArtist != null && customArtist.isNotEmpty)
          ? customArtist
          : (modelArtistValid ? model.artist! : 'Unknown artist'),
      album: model.album,
      uri: model.data,
      sourceType: AudioSourceType.local,
      artworkUri: customArtwork,
      duration: Duration(milliseconds: model.duration ?? 0),
      dateAdded: model.dateAdded != null
          ? DateTime.fromMillisecondsSinceEpoch(model.dateAdded! * 1000)
          : DateTime.now(),
      playCount: playCount,
      isFavorite: isFavorite,
    );
  }

  Widget buildArtwork(BuildContext context, {double width = 48, double height = 48, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    if (artworkUri != null && artworkUri!.isNotEmpty) {
      if (artworkUri!.startsWith('http')) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            artworkUri!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(context, width, height, radius),
          ),
        );
      } else {
        final file = File(artworkUri!);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: radius,
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context, width, height, radius),
            ),
          );
        }
      }
    }

    return QueryArtworkWidget(
      id: int.tryParse(id) ?? 0,
      type: ArtworkType.AUDIO,
      artworkWidth: width,
      artworkHeight: height,
      artworkBorder: radius,
      nullArtworkWidget: _placeholder(context, width, height, radius),
    );
  }

  Widget _placeholder(BuildContext context, double width, double height, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Icon(Icons.music_note, size: width / 2),
    );
  }
}
