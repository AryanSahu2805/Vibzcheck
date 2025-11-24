import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../providers/providers.dart';
import '../services/audio_service.dart';
import '../utils/helpers.dart';
import '../widgets/song_item.dart';

class PlaylistViewScreen extends ConsumerStatefulWidget {
  final String playlistId;
  const PlaylistViewScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends ConsumerState<PlaylistViewScreen> {
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    ref.read(playlistProviderInstance.notifier).loadPlaylist(widget.playlistId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }
  
  Future<void> _playPreview(SongModel song) async {
    try {
      if (song.previewUrl == null || song.previewUrl!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No preview available for this song'),
              backgroundColor: Color(0xFFE22134),
            ),
          );
        }
        return;
      }
      
      await _audioService.playPreview(
        songId: song.trackId, // Use Spotify track ID for consistent caching
        previewUrl: song.previewUrl!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing preview: $e'),
            backgroundColor: const Color(0xFFE22134),
          ),
        );
      }
    }
  }

  void _sharePlaylist(PlaylistModel playlist) {
    if (playlist.shareCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share code not available. Please try again.'),
          backgroundColor: Color(0xFFE22134),
        ),
      );
      return;
    }
    
    Share.share(
      'Join my playlist "${playlist.name}" on Vibzcheck!\n\n📱 Share Code: ${playlist.shareCode}\n\nSearch this code in the app to join the playlist and collaborate on music together!',
    );
  }

  Future<void> _deleteSong(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to remove "${song.trackName}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(playlistProviderInstance.notifier).deleteSong(
              playlistId: widget.playlistId,
              songId: song.id,
            );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${song.trackName}" from playlist'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete song: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePlaylist(BuildContext context) async {
    final playlist = ref.read(playlistProviderInstance).currentPlaylist;
    final currentUser = ref.read(authProviderInstance).currentUser;
    final messenger = ScaffoldMessenger.of(context);
    
    if (playlist == null || currentUser == null) return;
    
    // Verify user is creator
    if (playlist.creatorId != currentUser.uid) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Only the playlist creator can delete this playlist'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone. All songs and chat messages will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        
        await ref.read(playlistProviderInstance.notifier).deletePlaylist(
              playlistId: widget.playlistId,
              userId: currentUser.uid,
            );
        
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Playlist deleted successfully'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          
          // Navigate back to home
          navigator.pop();
        }
      } catch (e) {
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete playlist: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = ref.watch(playlistProviderInstance);
    final authProvider = ref.watch(authProviderInstance);
    final currentUser = authProvider.currentUser;
    final playlist = playlistProvider.currentPlaylist;
    final songs = playlistProvider.currentSongs;

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isCreator = currentUser?.uid == playlist.creatorId;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (playlist.coverImage != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: playlist.coverImage!,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.4),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.backgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (playlist.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                playlist.description!,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildInfoChip(
                                  Icons.person,
                                  Helpers.getBetterDisplayName(playlist.creatorName, null),
                                ),
                                const SizedBox(width: 12),
                                _buildInfoChip(
                                  Icons.music_note,
                                  '${playlist.songCount} songs',
                                ),
                                const SizedBox(width: 12),
                                _buildInfoChip(
                                  Icons.people,
                                  '${playlist.participants.length} members',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Share Code Display
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_open,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Code: ${playlist.shareCode}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePlaylist(playlist),
                tooltip: 'Share Playlist',
              ),
              if (isCreator)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'analytics',
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, size: 20),
                          SizedBox(width: 8),
                          Text('Analytics'),
                        ],
                      ),
                      onTap: () {
                        if (!mounted) return;
                        final navContext = context;
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              AppRoutes.navigateToAnalytics(navContext, widget.playlistId);
                            }
                          },
                        );
                      },
                    ),
                    PopupMenuItem<String>(
                      value: 'chat',
                      child: const Row(
                        children: [
                          Icon(Icons.chat, size: 20),
                          SizedBox(width: 8),
                          Text('Chat'),
                        ],
                      ),
                      onTap: () {
                        if (!mounted) return;
                        final navContext = context;
                        final playlistName = playlist.name;
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () {
                            if (mounted) {
                              AppRoutes.navigateToChat(
                                // ignore: use_build_context_synchronously
                                navContext,
                                widget.playlistId,
                                playlistName,
                              );
                            }
                          },
                        );
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete Playlist', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                      onTap: () {
                        if (!mounted) return;
                        final navContext = context;
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              _deletePlaylist(navContext);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => AppRoutes.navigateToSearch(
                            context,
                            playlistId: widget.playlistId,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Songs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => AppRoutes.navigateToChat(
                          context,
                          widget.playlistId,
                          playlist.name,
                        ),
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceColor,
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Participants Section
                  if (playlist.participants.isNotEmpty) ...[
                    Text(
                      'Participants',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: playlist.participants.length,
                        itemBuilder: (context, index) {
                          final participant = playlist.participants[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.surfaceColor,
                                  backgroundImage: participant.profilePicture != null
                                      ? CachedNetworkImageProvider(participant.profilePicture!)
                                      : null,
                                  child: participant.profilePicture == null
                                      ? Text(
                                          participant.displayName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    Helpers.getBetterDisplayName(participant.displayName, null),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Songs List
                  Text(
                    'Songs (${songs.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Songs List
          if (songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.queue_music,
                      size: 80,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add songs to get started!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  final hasUpvoted = currentUser != null &&
                      song.upvoters.contains(currentUser.uid);

                  final canDelete = currentUser != null && 
                      (isCreator || song.addedByUserId == currentUser.uid);

                  return SongItem(
                    song: song,
                    onTap: () => _playPreview(song),
                    onUpvote: currentUser != null
                        ? () {
                            ref.read(playlistProviderInstance.notifier).voteSong(
                                  playlistId: widget.playlistId,
                                  songId: song.id,
                                  userId: currentUser.uid,
                                  isUpvote: !hasUpvoted,
                                );
                          }
                        : null,
                    onDownvote: currentUser != null
                        ? () {
                            ref.read(playlistProviderInstance.notifier).voteSong(
                                  playlistId: widget.playlistId,
                                  songId: song.id,
                                  userId: currentUser.uid,
                                  isUpvote: false,
                                );
                          }
                        : null,
                    onDelete: canDelete
                        ? () => _deleteSong(song)
                        : null,
                  );
                },
                childCount: songs.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

