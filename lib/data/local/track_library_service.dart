import 'package:on_audio_query/on_audio_query.dart';

class TrackLibraryService {
  final OnAudioQuery _query = OnAudioQuery();

  Future<bool> requestPermission() {
    return _query.checkAndRequest();
  }

  Future<List<SongModel>> scanLibrary() {
    return _query.querySongs();
  }
}