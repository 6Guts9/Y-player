class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<String> trackIds ;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverArtUri;
/// we use List<String> instead of List<Track> because the later will store the whole track data
  /// this will cause issue because for example renaming or removing a track from a playlist would only update the library's copy
  /// every playlist holding an old copy of that track would be showing outdated info or the "deleted" track will still be displayed
  /// while storing ids means there's exactly one source of truth (the track library) and playlists just point at it
  const Playlist({

    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.trackIds = const [],
    this.coverArtUri,
});
  int get trackCount => trackIds.length;
  bool get isEmpty =>  trackIds.isEmpty;

  bool containsTracks(String trackId) => trackIds.contains(trackId);

  Playlist copyWith({
    String? name,
    String? description,
    List<String>? trackIds,
    String? coverArtUri,

}){
    return Playlist(
      id: id,
      name: name ?? this.name,
        description: description ?? this.description,
        trackIds: trackIds ?? this.trackIds,
        coverArtUri: coverArtUri ?? this.coverArtUri,
        createdAt: createdAt,
        updatedAt: DateTime.now(),

    );
  }
Playlist withTrackAdded(String trackId){
    if (containsTracks(trackId)) return this;
return copyWith(trackIds: [...trackIds,trackId]);
}
///playing a little with copyWith
  ///when adding a track to a playlist we unpack existing list items into a new list
  ///and then adds one more which is the new trackId
  ///the code is basically saying unpack every existing id from trackIds then add trackId as one more single element
Playlist withTrackRemoved(String trackId){
 return copyWith(trackIds: trackIds.where((id) => id != trackId).toList());
}
///while here when removing a track we filter the list looking for the specific id and then create a new list with copyWith
/// adding all the tracks except for the filtered one
}