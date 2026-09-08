import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/sorting.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../track.dart';
import '../providers/playlist_provider.dart';


List<Track> sortTracks(List<Track> tracks, LibrarySortOption option) {
  final sorted = [...tracks];
  switch (option) {
    case LibrarySortOption.dateAddedDesc:
      sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    case LibrarySortOption.dateAddedAsc:
      sorted.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
    case LibrarySortOption.titleAsc:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case LibrarySortOption.titleDesc:
      sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    case LibrarySortOption.durationAsc:
      sorted.sort((a, b) => a.duration.compareTo(b.duration));
    case LibrarySortOption.durationDesc:
      sorted.sort((a, b) => b.duration.compareTo(a.duration));
  }
  return sorted;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawTracks = ref.watch(trackLibraryProvider);
    final sortOption = ref.watch(librarySortProvider);

    final filteredTracks = rawTracks.where((track) {
      final query = _searchQuery.toLowerCase();
      return track.title.toLowerCase().contains(query) ||
             track.artist.toLowerCase().contains(query);
    }).toList();

    final tracks = sortTracks(filteredTracks, sortOption);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppBarTitle(),
          leading: _buildAppBarLeading(),
          actions: _buildAppBarActions(),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Artists'),
                  Tab(text: 'Albums'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: _isSelecting ? const NeverScrollableScrollPhysics() : null,
          children: [
            _buildSongsList(tracks),
            _buildArtistsList(tracks),
            _buildAlbumsList(tracks),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_isSelecting) return Text('${_selectedIds.length} selected');

    if (_isSearchActive) {
      return TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search songs or artists...',
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 18),
        onChanged: (value) => setState(() => _searchQuery = value),
      );
    }

    return const Text('Library');
  }

  Widget? _buildAppBarLeading() {
    if (_isSelecting) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      );
    }
    if (_isSearchActive) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchActive = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
      );
    }
    return null;
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelecting) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
      ];
    }

    if (_isSearchActive) {
      return [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearchActive = true),
      ),
      PopupMenuButton<LibrarySortOption>(
        icon: const Icon(Icons.sort),
        onSelected: (option) => ref.read(librarySortProvider.notifier).setOption(option),
        itemBuilder: (context) => const [
          PopupMenuItem(value: LibrarySortOption.dateAddedDesc, child: Text('Date added (newest)')),
          PopupMenuItem(value: LibrarySortOption.dateAddedAsc, child: Text('Date added (oldest)')),
          PopupMenuItem(value: LibrarySortOption.titleAsc, child: Text('Title (A–Z)')),
          PopupMenuItem(value: LibrarySortOption.titleDesc, child: Text('Title (Z–A)')),
          PopupMenuItem(value: LibrarySortOption.durationAsc, child: Text('Duration (shortest)')),
          PopupMenuItem(value: LibrarySortOption.durationDesc, child: Text('Duration (longest)')),
        ],
      ),
    ];
  }

  Widget _buildSongsList(List<Track> tracks) {
    if (tracks.isEmpty) {
      return const Center(child: Text('No songs found — pull down to refresh'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(trackLibraryProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final selected = _selectedIds.contains(track.id);
          
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index % 10 * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: ListTile(
              selected: selected,
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'artwork_${track.id}',
                    child: QueryArtworkWidget(
                      id: int.parse(track.id),
                      type: ArtworkType.AUDIO,
                      artworkWidth: 48,
                      artworkHeight: 48,
                      artworkBorder: BorderRadius.circular(8),
                      nullArtworkWidget: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                ],
              ),
              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: _isSelecting
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.playlist_add),
                      onPressed: () => _showAddToPlaylist(context, track),
                    ),
              onLongPress: () => _toggleSelected(track.id),
              onTap: _isSelecting
                  ? () => _toggleSelected(track.id)
                  : () => ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistsList(List<Track> tracks) {
    final artists = tracks.map((t) => t.artist).toSet().toList()..sort();
    if (artists.isEmpty) return const Center(child: Text('No artists found'));

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final artistTracks = tracks.where((t) => t.artist == artist).toList();
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index % 10 * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(artist),
            subtitle: Text('${artistTracks.length} tracks'),
            onTap: () => _showTracksDialog(context, artist, artistTracks),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsList(List<Track> tracks) {
    final albums = tracks.map((t) => t.album ?? 'Unknown Album').toSet().toList()..sort();
    if (albums.isEmpty) return const Center(child: Text('No albums found'));

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final albumTracks = tracks.where((t) => (t.album ?? 'Unknown Album') == album).toList();
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index % 10 * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.album)),
            title: Text(album),
            subtitle: Text(albumTracks.first.artist),
            trailing: Text('${albumTracks.length} tracks'),
            onTap: () => _showTracksDialog(context, album, albumTracks),
          ),
        );
      },
    );
  }

  void _showTracksDialog(BuildContext context, String title, List<Track> tracks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: int.parse(track.id),
                      type: ArtworkType.AUDIO,
                      artworkWidth: 40,
                      artworkHeight: 40,
                      artworkBorder: BorderRadius.circular(4),
                      nullArtworkWidget: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.music_note, size: 20),
                      ),
                    ),
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    onTap: () {
                      ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tracks?'),
        content: Text('Remove ${_selectedIds.length} tracks from your device and library?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final count = _selectedIds.length;
              final failed = await ref.read(trackLibraryProvider.notifier).deleteTracks(_selectedIds);
              
              if (!mounted) return;
              
              if (failed > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${count - failed} tracks. $failed failed.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted $count tracks')),
                );
              }
              
              _clearSelection();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final playlists = ref.watch(playlistProvider);
          if (playlists.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No playlists yet — create one from the Playlists tab'),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final playlist in playlists)
                ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    ref.read(playlistProvider.notifier).addTrack(playlist.id, track.id);
                    Navigator.pop(context);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

