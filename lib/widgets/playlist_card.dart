import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist_model.dart';
import '../config/theme.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback? onTap;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: playlist.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: playlist.coverImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.surfaceColor,
                          child: const Icon(Icons.music_note),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.queue_music, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${playlist.creatorName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.music_note, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.songCount} songs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.participants.length} members',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}