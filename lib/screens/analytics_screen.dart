import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/firestore_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final String playlistId;
  const AnalyticsScreen({super.key, required this.playlistId});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: StreamBuilder<PlaylistModel?>(
        stream: _firestoreService.getPlaylistStream(widget.playlistId),
        builder: (context, playlistSnapshot) {
          if (!playlistSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final playlist = playlistSnapshot.data!;

          return StreamBuilder<List<SongModel>>(
            stream: _firestoreService.getPlaylistSongs(widget.playlistId),
            builder: (context, songsSnapshot) {
              final songs = songsSnapshot.data ?? [];
              
              // Calculate statistics
              final totalVotes = songs.fold<int>(
                0,
                (sum, song) => sum + song.voteScore,
              );
              final mostVotedSong = songs.isNotEmpty
                  ? songs.reduce((a, b) => a.voteScore > b.voteScore ? a : b)
                  : null;
              final totalDuration = songs.fold<Duration>(
                Duration.zero,
                (sum, song) => sum + song.duration,
              );
              final topContributor = _getTopContributor(songs);
              final moodDistribution = _getMoodDistribution(songs);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Songs',
                            '${songs.length}',
                            Icons.music_note,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Votes',
                            '$totalVotes',
                            Icons.how_to_vote,
                            AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Duration',
                            _formatDuration(totalDuration),
                            Icons.timer,
                            AppTheme.infoColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Members',
                            '${playlist.participants.length}',
                            Icons.people,
                            AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Most Voted Song
                    if (mostVotedSong != null) ...[
                      Text(
                        'Most Voted Song',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: mostVotedSong.albumArtUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mostVotedSong.trackName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mostVotedSong.artistName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    color: AppTheme.successColor,
                                  ),
                                  Text(
                                    '${mostVotedSong.voteScore}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Top Contributor
                    if (topContributor != null) ...[
                      Text(
                        'Top Contributor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.surfaceColor,
                                child: Text(
                                  topContributor['name'][0].toUpperCase(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topContributor['name'],
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${topContributor['count']} songs added',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: AppTheme.warningColor,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Mood Distribution
                    if (moodDistribution.isNotEmpty) ...[
                      Text(
                        'Mood Distribution',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...moodDistribution.entries.map((entry) {
                        final percentage = (entry.value / songs.length * 100).toStringAsFixed(0);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: entry.value / songs.length,
                                        backgroundColor: AppTheme.surfaceColor,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '$percentage%',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
    );
                      }),
                    ],
                    // Recent Activity
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActivityItem(
                              Icons.add_circle,
                              'Playlist created',
                              playlist.createdAt,
                            ),
                            if (playlist.updatedAt != playlist.createdAt)
                              _buildActivityItem(
                                Icons.update,
                                'Last updated',
                                playlist.updatedAt,
                              ),
                            _buildActivityItem(
                              Icons.people,
                              '${playlist.participants.length} members joined',
                              playlist.participants.isNotEmpty
                                  ? playlist.participants.last.joinedAt
                                  : playlist.createdAt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String text, DateTime dateTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(dateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getMoodDistribution(List<SongModel> songs) {
    final distribution = <String, int>{};
    for (final song in songs) {
      for (final mood in song.moodTags) {
        distribution[mood] = (distribution[mood] ?? 0) + 1;
      }
    }
    return distribution;
  }

  Map<String, dynamic>? _getTopContributor(List<SongModel> songs) {
    if (songs.isEmpty) return null;

    final contributorCounts = <String, int>{};
    for (final song in songs) {
      contributorCounts[song.addedByDisplayName] =
          (contributorCounts[song.addedByDisplayName] ?? 0) + 1;
    }

    if (contributorCounts.isEmpty) return null;

    final topContributor = contributorCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {
      'name': topContributor.key,
      'count': topContributor.value,
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
