enum AudioSourceType {local,remote}
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
}
///The == and hashCode override by default,
/// Dart compares two objects by whether they're literally the same object in memory
/// we want two Tracks with the same id to be treated as "the same track" even if one is a slightly newer copy for examole in case of copyWith bumped playCount
/// overriding "==" lets you write list.contains(track) or trackA == trackB and get sensible results
/// hashCode has to be overridden alongside it
///it's a Dart rule: if two objects are == equal ,they must produce the same hashcode or things like Set and Map lookups break.
