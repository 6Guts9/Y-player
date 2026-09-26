import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/services/discovery_service.dart';
import '../../../../../core/themes/theme_picker_screen.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../track.dart';

class RecommendationSection {
  final String title;
  final String query;
  final List<DiscoveryTrack> tracks;

  RecommendationSection({required this.title, required this.query, required this.tracks});
}

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DiscoveryTrack> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  DiscoverySource _selectedSource = DiscoverySource.soundcloud;
  final Map<String, double> _downloadProgress = {};

  // YouTube WebView variables
  late final WebViewController _webViewController;
  String? _currentYoutubeUrl;
  bool _isYoutubeVideoPage = false;
  bool _isDownloadingYoutube = false;
  double _youtubeDownloadProgress = 0.0;

  List<RecommendationSection> _recommendations = [];
  bool _isLoadingFeed = false;
  List<String> _sortedArtists = [];
  int _artistIndexCursor = 0;
  final Map<int, String> _sectionArtists = {};

  String _selectedGenreKey = 'all';
  final Map<String, List<DiscoveryTrack>> _genreTracks = {};
  bool _isLoadingGenre = false;

  final List<Map<String, String>> _genreDefs = [
    {'label': 'Hip-Hop & Rap', 'key': 'hiphoprap', 'query': 'hip hop rap'},
    {'label': 'Lo-Fi & Ambient', 'key': 'ambient', 'query': 'lofi ambient'},
    {'label': 'Rock', 'key': 'rock', 'query': 'rock music'},
    {'label': 'Pop', 'key': 'pop', 'query': 'pop hits'},
    {'label': 'Dance & EDM', 'key': 'danceedm', 'query': 'dance edm'},
    {'label': 'R&B & Soul', 'key': 'rb-soul', 'query': 'rnb soul'},
    {'label': 'Indie', 'key': 'indie', 'query': 'indie music'},
  ];

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            _checkYoutubeUrl(change.url);
          },
          onPageStarted: (String url) {
            _checkYoutubeUrl(url);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSoundCloudFeed();
    });
  }

  void _checkYoutubeUrl(String? url) {
    if (url == null) return;
    final isVideo = url.contains('watch?v=') || url.contains('youtu.be/');
    if (mounted && (_currentYoutubeUrl != url || _isYoutubeVideoPage != isVideo)) {
      setState(() {
        _currentYoutubeUrl = url;
        _isYoutubeVideoPage = isVideo;
      });
    }
  }

  Future<void> _handleYoutubeDownload() async {
    if (_currentYoutubeUrl == null) return;
    setState(() {
      _isDownloadingYoutube = true;
      _youtubeDownloadProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extracting & downloading YouTube audio...')),
    );

    final file = await ref.read(discoveryServiceProvider).downloadYoutubeVideo(
      _currentYoutubeUrl!,
      onProgress: (p) => setState(() => _youtubeDownloadProgress = p),
    );

    if (mounted) {
      setState(() => _isDownloadingYoutube = false);
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${file.path.split('/').last}')),
        );
        await ref.read(trackLibraryProvider.notifier).scanAndRefresh(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube download failed')),
        );
      }
    }
  }

  Future<void> _loadSoundCloudFeed() async {
    if (_selectedSource != DiscoverySource.soundcloud) return;

    setState(() => _isLoadingFeed = true);

    try {
      final service = ref.read(discoveryServiceProvider);
      final library = ref.read(trackLibraryProvider);

      final artistCounts = <String, int>{};
      for (final t in library) {
        String clean = t.artist.trim();
        if (clean.isEmpty ||
            clean.toLowerCase().contains('unknown') ||
            clean.toLowerCase().contains('track') ||
            clean.toLowerCase().contains('<unknown>')) {
          continue;
        }
        if (clean.toLowerCase().contains(' feat')) {
          clean = clean.split(RegExp(r'\s+feat', caseSensitive: false)).first;
        }
        if (clean.toLowerCase().contains(' ft.')) {
          clean = clean.split(RegExp(r'\s+ft\.', caseSensitive: false)).first;
        }
        clean = clean.trim();
        if (clean.isNotEmpty) {
          artistCounts[clean] = (artistCounts[clean] ?? 0) + (t.isFavorite ? 3 : 1);
        }
      }

      _sortedArtists = artistCounts.keys.toList()
        ..sort((a, b) => artistCounts[b]!.compareTo(artistCounts[a]!));
      _artistIndexCursor = 0;
      _sectionArtists.clear();

      final recQueries = <String>[];
      final recTitles = <String>[];

      for (final artist in _sortedArtists) {
        if (recQueries.length >= 2) break;
        recQueries.add(artist);
        recTitles.add('More of "$artist"');
        _sectionArtists[recQueries.length - 1] = artist;
        _artistIndexCursor++;
      }

      final fallbackRecs = [
        {'title': 'Featured: Lo-Fi Chill Beats', 'query': 'lofi chill beats'},
        {'title': 'Featured: Acoustic Chill', 'query': 'acoustic chill'},
      ];

      for (final fb in fallbackRecs) {
        if (recQueries.length >= 2) break;
        if (!recQueries.contains(fb['query'])) {
          recQueries.add(fb['query']!);
          recTitles.add(fb['title']!);
        }
      }

      final genreKeys = _genreDefs.map((g) => g['key']!).toList();
      final recFutures = recQueries.map((q) => service.search(q, source: DiscoverySource.soundcloud));
      final genresFuture = service.fetchTopTracksByGenre(genres: genreKeys);

      final results = await Future.wait([
        Future.wait(recFutures),
        genresFuture,
      ]);

      final recResults = results[0] as List<List<DiscoveryTrack>>;
      final genreResultsMap = results[1] as Map<String, List<DiscoveryTrack>>;

      final loadedRecSections = <RecommendationSection>[];
      for (var i = 0; i < recQueries.length; i++) {
        if (recResults[i].isNotEmpty) {
          loadedRecSections.add(RecommendationSection(
            title: recTitles[i],
            query: recQueries[i],
            tracks: recResults[i].take(8).toList(),
          ));
        }
      }

      final loadedGenreTracks = <String, List<DiscoveryTrack>>{};
      for (final gDef in _genreDefs) {
        final key = gDef['key']!;
        var tracks = genreResultsMap[key];
        if (tracks == null || tracks.isEmpty) {
          try {
            tracks = await service.search(gDef['query']!, source: DiscoverySource.soundcloud);
          } catch (_) {}
        }
        if (tracks != null && tracks.isNotEmpty) {
          loadedGenreTracks[key] = tracks.take(20).toList();
        }
      }

      if (mounted) {
        setState(() {
          _recommendations = loadedRecSections;
          _genreTracks.clear();
          _genreTracks.addAll(loadedGenreTracks);
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFeed = false);
      }
    }
  }

  Future<void> _refreshArtist(int sectionIndex) async {
    if (_isLoadingFeed) return;

    String? newQuery;
    String newTitle = '';

    if (_sortedArtists.isNotEmpty) {
      final activeArtists = _sectionArtists.values.toSet();
      for (int i = 0; i < _sortedArtists.length; i++) {
        final candidate = _sortedArtists[_artistIndexCursor % _sortedArtists.length];
        _artistIndexCursor++;
        if (!activeArtists.contains(candidate)) {
          newQuery = candidate;
          newTitle = 'More of "$candidate"';
          break;
        }
      }
      if (newQuery == null && _sortedArtists.isNotEmpty) {
        newQuery = _sortedArtists[_artistIndexCursor % _sortedArtists.length];
        _artistIndexCursor++;
        newTitle = 'More of "$newQuery"';
      }
    }

    if (newQuery == null) {
      final fallbacks = ['lofi chill beats', 'acoustic chill', 'synthwave', 'indie rock', 'electronic ambient'];
      newQuery = fallbacks[DateTime.now().microsecond % fallbacks.length];
      newTitle = newQuery.split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }

    final query = newQuery;

    setState(() => _isLoadingFeed = true);

    try {
      final service = ref.read(discoveryServiceProvider);
      final tracks = await service.search(query, source: DiscoverySource.soundcloud);

      if (tracks.isNotEmpty && mounted) {
        setState(() {
          _sectionArtists[sectionIndex] = query;
          if (sectionIndex < _recommendations.length) {
            _recommendations[sectionIndex] = RecommendationSection(
              title: newTitle,
              query: query,
              tracks: tracks.take(8).toList(),
            );
          }
          _isLoadingFeed = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoadingFeed = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load more tracks for this artist. Try refreshing again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFeed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh artist: $e')),
        );
      }
    }
  }

  Future<void> _selectGenre(String key) async {
    setState(() {
      _selectedGenreKey = key;
    });
    if (key != 'all' && (_genreTracks[key] == null || _genreTracks[key]!.isEmpty)) {
      setState(() => _isLoadingGenre = true);
      try {
        final service = ref.read(discoveryServiceProvider);
        final genreDef = _genreDefs.firstWhere((g) => g['key'] == key, orElse: () => {'query': key});
        final query = genreDef['query'] ?? key;
        final tracks = await service.search(query, source: DiscoverySource.soundcloud);
        if (mounted) {
          setState(() {
            _genreTracks[key] = tracks;
            _isLoadingGenre = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingGenre = false);
        }
      }
    }
  }

  Future<void> _handleSearch() async {
    if (_controller.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final results = await ref.read(discoveryServiceProvider).search(
        _controller.text,
        source: _selectedSource,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found. Try a different search.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _onSearchPressed() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    } else if (_controller.text.isNotEmpty) {
      _handleSearch();
    }
  }

  Future<void> _playTrack(DiscoveryTrack dt) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching audio stream...'), duration: Duration(seconds: 2)),
    );
    try {
      final url = await ref.read(discoveryServiceProvider).getAudioStreamUrl(dt);
      if (url != null) {
        final track = Track(
          id: dt.id,
          title: dt.title,
          artist: dt.artist,
          uri: url,
          sourceType: AudioSourceType.remote,
          dateAdded: DateTime.now(),
          duration: dt.duration,
          artworkUri: dt.thumbnailUrl,
        );
        ref.read(playerProvider.notifier).playTrack(track);
      } else {
        throw Exception('Stream URL was null');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play track: $e')),
        );
      }
    }
  }

  Future<void> _downloadTrack(DiscoveryTrack dt) async {
    setState(() => _downloadProgress[dt.id] = 0.0);
    final file = await ref.read(discoveryServiceProvider).download(
      dt,
      onProgress: (p) => setState(() => _downloadProgress[dt.id] = p),
    );

    if (file != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${dt.title}')),
        );
      }
      await ref.read(trackLibraryProvider.notifier).scanAndRefresh(file.path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed')),
        );
      }
    }
    setState(() => _downloadProgress.remove(dt.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: 'Search for music...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _handleSearch(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _onSearchPressed),
          IconButton(
            icon: const Icon(Icons.palette),
            color: Theme.of(context).colorScheme.primary,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SegmentedButton<DiscoverySource>(
              segments: const [
                ButtonSegment(
                  value: DiscoverySource.soundcloud,
                  label: Text('SoundCloud'),
                  icon: Icon(Icons.cloud_outlined),
                ),
                ButtonSegment(
                  value: DiscoverySource.youtube,
                  label: Text('YouTube'),
                  icon: Icon(Icons.play_circle_outline),
                ),
                ButtonSegment(
                  value: DiscoverySource.archive,
                  label: Text('Archive.org'),
                  icon: Icon(Icons.account_balance_outlined),
                ),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (Set<DiscoverySource> newSelection) {
                setState(() {
                  _selectedSource = newSelection.first;
                  if (_selectedSource == DiscoverySource.soundcloud) {
                    if (_recommendations.isEmpty) {
                      _loadSoundCloudFeed();
                    }
                  } else if (_controller.text.isNotEmpty) {
                    _handleSearch();
                  } else {
                    _hasSearched = false;
                    _results = [];
                  }
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_selectedSource == DiscoverySource.youtube)
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (_isYoutubeVideoPage)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.red),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'YouTube Track Detected',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_isDownloadingYoutube)
                                SizedBox(
                                  width: 130,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LinearProgressIndicator(value: _youtubeDownloadProgress),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Downloading: ${(_youtubeDownloadProgress * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                FilledButton.icon(
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download MP3'),
                                  onPressed: () => _handleYoutubeDownload(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (_selectedSource == DiscoverySource.archive && _results.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Archive.org tracks are unseekable and some may not play.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedSource != DiscoverySource.youtube)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isNotEmpty
                      ? ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) => _buildTrackTile(_results[index]),
                        )
                      : _hasSearched
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedSource == DiscoverySource.soundcloud ? Icons.cloud_off : Icons.history_edu,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _selectedSource == DiscoverySource.soundcloud
                                          ? 'No SoundCloud results found.'
                                          : 'No Archive.org results found.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedSource == DiscoverySource.soundcloud
                                          ? 'Try searching for a different artist or song name.'
                                          : 'Archive.org mostly hosts live concerts, public domain recordings, and audiobooks.\n\nNote: The music bar is unseekable and not all tracks work.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _selectedSource == DiscoverySource.soundcloud
                              ? _buildSoundCloudHomeFeed()
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Search for your favorite music'),
                                    ],
                                  ),
                                ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudHomeFeed() {
    if (_isLoadingFeed) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Home'),
                  selected: _selectedGenreKey == 'all',
                  onSelected: (_) => _selectGenre('all'),
                ),
              ),
              for (final g in _genreDefs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g['label']!),
                    selected: _selectedGenreKey == g['key'],
                    onSelected: (_) => _selectGenre(g['key']!),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _selectedGenreKey == 'all'
              ? _buildHomeFeedContent()
              : _buildSelectedGenreContent(),
        ),
      ],
    );
  }

  Widget _buildHomeFeedContent() {
    if (_recommendations.isEmpty && _genreTracks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadSoundCloudFeed(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Could not load feed. Pull down to refresh.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSoundCloudFeed(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_recommendations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            for (var i = 0; i < _recommendations.length; i++) ...[
              () {
                final rec = _recommendations[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rec.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => _refreshArtist(i),
                        tooltip: 'Refresh artist',
                      ),
                    ],
                  ),
                );
              }(),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _recommendations[i].tracks.length,
                  itemBuilder: (context, trackIndex) => _buildHorizontalTrackCard(_recommendations[i].tracks[trackIndex]),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],

          if (_genreTracks.isNotEmpty) ...[
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Explore Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            for (final gDef in _genreDefs) ...[
              if (_genreTracks[gDef['key']] != null && _genreTracks[gDef['key']]!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        gDef['label']!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => _selectGenre(gDef['key']!),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
                ..._genreTracks[gDef['key']]!.take(3).map((track) => _buildTrackTile(track)),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedGenreContent() {
    if (_isLoadingGenre) {
      return const Center(child: CircularProgressIndicator());
    }

    final tracks = _genreTracks[_selectedGenreKey] ?? [];

    if (tracks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _selectGenre(_selectedGenreKey),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('No tracks found for this genre. Pull down to refresh.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _selectGenre(_selectedGenreKey),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tracks.length,
        itemBuilder: (context, index) => _buildTrackTile(tracks[index]),
      ),
    );
  }

  Widget _buildHorizontalTrackCard(DiscoveryTrack track) {
    return InkWell(
      onTap: () => _playTrack(track),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track.thumbnailUrl,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 130,
                      height: 130,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.music_note),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      onPressed: () => _playTrack(track),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(DiscoveryTrack track) {
    final progress = _downloadProgress[track.id];

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.thumbnailUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress != null)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(value: progress, strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadTrack(track),
            ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _playTrack(track),
          ),
        ],
      ),
      onTap: () => _playTrack(track),
    );
  }
}
