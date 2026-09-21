import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/discovery_service.dart';
import '../../../../../core/themes/theme_picker_screen.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../track.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _controller = TextEditingController();
  List<DiscoveryTrack> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  DiscoverySource _selectedSource = DiscoverySource.soundcloud;
  final Map<String, double> _downloadProgress = {};

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
      // Force Android to index the new file instantly so it shows in Library
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search for music...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _handleSearch(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _handleSearch),
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
                  value: DiscoverySource.archive,
                  label: Text('Archive.org'),
                  icon: Icon(Icons.account_balance_outlined),
                ),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (Set<DiscoverySource> newSelection) {
                setState(() {
                  _selectedSource = newSelection.first;
                  if (_controller.text.isNotEmpty) {
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
          if (_selectedSource == DiscoverySource.archive && _results.isNotEmpty)
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _hasSearched
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedSource == DiscoverySource.soundcloud ? Icons.cloud_off : Icons.history_edu,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                const Text('Search for your favorite music'),
                              ],
                            ),
                          )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final track = _results[index];
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
