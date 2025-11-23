import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/providers.dart';
import '../services/spotify_service.dart';
import '../widgets/custom_text_field.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? playlistId;
  const SearchScreen({super.key, this.playlistId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpotifyService _spotifyService = SpotifyService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (!_spotifyService.isAuthorized) {
      setState(() {
        _error = 'Please authorize with Spotify first';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _spotifyService.searchTracks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }
  
  Future<void> _connectSpotifyAndRetry() async {
    final authProvider = ref.read(authProviderInstance.notifier);
    try {
      final success = await authProvider.connectSpotify();
      if (success && mounted) {
        setState(() {
          _error = null;
        });
        // Retry search with previous query
        if (_searchController.text.isNotEmpty) {
          _searchSongs(_searchController.text);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to connect Spotify: $e';
        });
      }
    }
  }

  Future<void> _addSong(Map<String, dynamic> track) async {
    if (widget.playlistId == null) return;

    final user = ref.read(authProviderInstance).currentUser;
    if (user == null) return;

    try {
      await ref.read(playlistProviderInstance.notifier).addSong(
        playlistId: widget.playlistId!,
        trackData: track,
        userId: user.uid,
        displayName: user.displayName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${track['name']}" to playlist'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding song: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDuration(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search for songs',
              prefixIcon: Icons.search,
              hint: 'Type song name, artist...',
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchSongs(value);
                  }
                });
              },
            ),
          ),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search Error',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_error!.contains('authorize'))
                              Column(
                                children: [
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _connectSpotifyAndRetry,
                                    icon: const Icon(Icons.music_note),
                                    label: const Text('Connect Spotify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 80,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for songs',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find and add songs to your playlist',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final track = _searchResults[index];
                              final album = track['album'] as Map<String, dynamic>?;
                              final artists = track['artists'] as List<dynamic>?;
                              final artistName = artists != null && artists.isNotEmpty
                                  ? artists[0]['name'] as String
                                  : 'Unknown Artist';
                              final albumImage = album?['images'] != null &&
                                      (album!['images'] as List).isNotEmpty
                                  ? (album['images'] as List)[0]['url'] as String
                                  : null;
                              final duration = track['duration_ms'] as int? ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: widget.playlistId != null
                                      ? () => _addSong(track)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Album Art
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: albumImage != null
                                              ? CachedNetworkImage(
                                                  imageUrl: albumImage,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: AppTheme.surfaceColor,
                                                    child: const Icon(Icons.music_note),
                                                  ),
                                                )
                                              : Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: AppTheme.surfaceColor,
                                                  child: const Icon(Icons.music_note),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Track Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                track['name'] as String? ?? 'Unknown',
                                                style: Theme.of(context).textTheme.titleMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                artistName,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                album?['name'] as String? ?? '',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textTertiary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Duration & Add Button
                                        Column(
                                          children: [
                                            Text(
                                              _formatDuration(duration),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (widget.playlistId != null)
                                              IconButton(
                                                icon: const Icon(Icons.add_circle),
                                                color: AppTheme.primaryColor,
                                                onPressed: () => _addSong(track),
                                                tooltip: 'Add to playlist',
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
