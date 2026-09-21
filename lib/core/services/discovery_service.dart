import 'dart:io';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum DiscoverySource { soundcloud, archive }

class DiscoveryTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String thumbnailUrl;
  final Duration duration;
  final DiscoverySource source;
  final String? streamUrl;

  DiscoveryTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.thumbnailUrl,
    required this.duration,
    required this.source,
    this.streamUrl,
  });
}

class DiscoveryService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
    },
  ));

  String? _scClientId;
  Future<String?>? _pendingFetch;

  DiscoveryService() {
    _initSC();
  }

  Future<void> _initSC() async {
    _scClientId = await _fetchFreshClientId();
  }

  Future<String?> _fetchFreshClientId() {
    return _pendingFetch ??= _doFetchFreshClientId().whenComplete(() {
      _pendingFetch = null;
    });
  }

  Future<String?> _doFetchFreshClientId() async {
    try {
      print('DISCOVERY: Fetching fresh SoundCloud Client ID...');
      // 1. Load the main page to find JS asset links
      final page = await _dio.get('https://soundcloud.com');
      final scriptUrls = RegExp(r'src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"')
          .allMatches(page.data.toString())
          .map((m) => m.group(1)!)
          .toList();

      // 2. Scan scripts (starting from newest/bottom) for the ID pattern
      for (final url in scriptUrls.reversed) {
        try {
          final js = await _dio.get(url);
          final match = RegExp(r'client_id\s*[:=]\s*"([0-9a-zA-Z]{32})"').firstMatch(js.data.toString());
          if (match != null) {
            final id = match.group(1);
            print('DISCOVERY: Successfully extracted SoundCloud ID: $id');
            return id;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      print('DISCOVERY ERROR: Failed to scrape SoundCloud ID: $e');
    }
    return null;
  }

  Future<List<DiscoveryTrack>> search(String query, {DiscoverySource source = DiscoverySource.soundcloud}) async {
    if (source == DiscoverySource.soundcloud) {
      // Ensure we have an ID
      _scClientId ??= await _fetchFreshClientId();
      if (_scClientId == null) {
        print('DISCOVERY: No SoundCloud client ID available, aborting search');
        return [];
      }
      
      var results = await _searchSoundCloud(query);
      
      // If we got a 401, the ID might have just expired, try one refresh
      if (results.isEmpty) {
        _scClientId = await _fetchFreshClientId();
        if (_scClientId != null) {
          results = await _searchSoundCloud(query);
        }
      }
      return results;
    } else {
      return _searchArchive(query);
    }
  }

  Future<List<DiscoveryTrack>> _searchSoundCloud(String query) async {
    try {
      final response = await _dio.get(
        'https://api-v2.soundcloud.com/search/tracks',
        queryParameters: {
          'q': query,
          'client_id': _scClientId,
          'limit': 25,
        },
      );

      if (response.statusCode == 200) {
        final List items = response.data['collection'] ?? [];
        final tracks = <DiscoveryTrack>[];
        for (var item in items) {
          try {
            final user = item['user']?['username'] ?? 'Unknown Artist';
            tracks.add(DiscoveryTrack(
              id: item['id'].toString(),
              title: item['title'] ?? 'Unknown',
              artist: user,
              album: item['publisher_metadata']?['album_title'] ?? 'SoundCloud',
              thumbnailUrl: item['artwork_url']?.replaceAll('large', 't500x500') ?? item['user']?['avatar_url'] ?? '',
              duration: Duration(milliseconds: item['duration'] ?? 0),
              source: DiscoverySource.soundcloud,
            ));
          } catch (e) {
            print('Error parsing SoundCloud item: $e');
          }
        }
        print('DISCOVERY: Found ${tracks.length} SoundCloud results');
        return tracks;
      }
    } catch (e) {
      print('SoundCloud Search error: $e');
    }
    return [];
  }

  Future<List<DiscoveryTrack>> _searchArchive(String query) async {
    try {
      final response = await _dio.get(
        'https://archive.org/advancedsearch.php',
        queryParameters: {
          'q': '($query) AND mediatype:audio',
          'output': 'json',
          'rows': 25,
          'fl[]': ['identifier', 'title', 'creator', 'runtime', 'album'],
        },
      );

      if (response.statusCode == 200) {
        if (response.data['error'] != null) {
          print('Archive.org API error: ${response.data['error']}');
          return [];
        }
        final List items = response.data['response']?['docs'] ?? [];
        final tracks = <DiscoveryTrack>[];
        for (var item in items) {
          try {
            final id = item['identifier'];
            if (id == null) continue;
            tracks.add(DiscoveryTrack(
              id: id,
              title: item['title'] ?? 'Unknown',
              artist: item['creator'] is List ? item['creator'][0] : item['creator'] ?? 'Unknown Artist',
              album: item['album'] ?? 'Archive.org',
              thumbnailUrl: 'https://archive.org/services/img/$id',
              duration: _parseArchiveRuntime(item['runtime']),
              source: DiscoverySource.archive,
            ));
          } catch (e) {
            print('Error parsing Archive item: $e');
          }
        }
        print('DISCOVERY: Found ${tracks.length} Archive.org results');
        return tracks;
      }
    } catch (e) {
      print('Archive.org Search error: $e');
    }
    return [];
  }

  Future<String?> getAudioStreamUrl(DiscoveryTrack track) async {
    if (track.source == DiscoverySource.soundcloud) {
      return _getSoundCloudStream(track.id);
    } else {
      return _getArchiveStream(track.id);
    }
  }

  Future<String?> _getSoundCloudStream(String trackId) async {
    for (var i = 0; i < 2; i++) {
      try {
        _scClientId ??= await _fetchFreshClientId();
        if (_scClientId == null) return null;

        final response = await _dio.get(
          'https://api-v2.soundcloud.com/tracks/$trackId',
          queryParameters: {'client_id': _scClientId},
        );

        if (response.statusCode == 200) {
          final List transcodings = response.data['media']?['transcodings'] ?? [];
          final stream = transcodings.firstWhere(
            (t) => t['format']?['protocol'] == 'progressive',
            orElse: () => transcodings.isNotEmpty ? transcodings.first : null,
          );

          if (stream != null) {
            final redirectResponse = await _dio.get(
              stream['url'],
              queryParameters: {'client_id': _scClientId},
            );
            return redirectResponse.data['url'];
          }
        }
      } catch (e) {
        print('SoundCloud Stream error: $e');
        _scClientId = null; // Reset to force fetch on retry
      }
    }
    return null;
  }

  Future<String?> _getArchiveStream(String identifier) async {
    try {
      final response = await _dio.get('https://archive.org/metadata/$identifier');
      if (response.statusCode == 200) {
        final List files = response.data['files'] ?? [];

        // Prefer IA's own re-encoded derivative — it has a proper seek table.
        // The raw "original" upload frequently lacks one, which is why
        // seeking silently fails on ExoPlayer for those files.
        var audioFile = files.firstWhere(
          (f) => f['source'] == 'derivative' &&
              (f['name'].toString().endsWith('.mp3') || f['name'].toString().endsWith('.ogg')),
          orElse: () => null,
        );

        // Fallback to original if no derivative exists
        audioFile ??= files.firstWhere(
          (f) => f['name'].toString().endsWith('.mp3') || f['name'].toString().endsWith('.ogg'),
          orElse: () => null,
        );

        if (audioFile != null) {
          return 'https://archive.org/download/$identifier/${audioFile['name']}';
        }
      }
    } catch (e) {
      print('Archive Stream error: $e');
    }
    return null;
  }

  Duration _parseArchiveRuntime(dynamic runtime) {
    if (runtime == null || runtime.toString().isEmpty) return Duration.zero;
    try {
      final parts = runtime.toString().split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: int.tryParse(parts[2]) ?? 0,
        );
      } else if (parts.length == 2) {
        return Duration(
          minutes: int.tryParse(parts[0]) ?? 0,
          seconds: int.tryParse(parts[1]) ?? 0,
        );
      } else if (parts.length == 1) {
        return Duration(seconds: int.tryParse(parts[0]) ?? 0);
      }
    } catch (_) {}
    return Duration.zero;
  }

  Future<File?> download(DiscoveryTrack track, {Function(double)? onProgress}) async {
    File? file;
    try {
      final streamUrl = await getAudioStreamUrl(track);
      if (streamUrl == null) return null;

      Directory? musicDir;
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Music/YPlayer');
        if (!await directory.exists()) await directory.create(recursive: true);
        musicDir = directory;
      }
      musicDir ??= await getApplicationDocumentsDirectory();

      // Detect extension from URL or fallback to mp3
      String extension = 'mp3';
      if (streamUrl.contains('.ogg')) extension = 'ogg';
      if (streamUrl.contains('.m4a')) extension = 'm4a';
      if (streamUrl.contains('.wav')) extension = 'wav';

      final fileName = '${track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.$extension';
      file = File('${musicDir.path}/$fileName');
      if (await file.exists()) await file.delete();

      print('DOWNLOAD: Starting download from $streamUrl');
      // 1. Download the audio file
      await _dio.download(
        streamUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) onProgress?.call(received / total);
        },
      );

      // 2. Fetch artwork bytes
      List<int>? artworkBytes;
      if (track.thumbnailUrl.isNotEmpty) {
        try {
          final artResp = await _dio.get<List<int>>(
            track.thumbnailUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          artworkBytes = artResp.data;
        } catch (_) {}
      }

      // 3. Write ID3 Tags
      try {
        final tags = Tag(
          title: track.title,
          trackArtist: track.artist,
          album: track.album,
          pictures: artworkBytes != null ? [
            Picture(
              bytes: Uint8List.fromList(artworkBytes),
              mimeType: MimeType.png, // Default to png, lib handles conversion
              pictureType: PictureType.other,
            )
          ] : [],
        );
        await AudioTags.write(file.path, tags);
      } catch (e) {
        print('Metadata embedding error: $e');
      }

      final size = (await file.stat()).size;
      return size > 1000 ? file : null;
    } catch (e) {
      print('DOWNLOAD ERROR: $e');
      if (file != null && await file.exists()) await file.delete();
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }
}

final discoveryServiceProvider = Provider((ref) {
  final service = DiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});
