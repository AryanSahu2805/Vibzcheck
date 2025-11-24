import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class SongItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onDelete;

  const SongItem({
    super.key,
    required this.song,
    this.onTap,
    this.onUpvote,
    this.onDownvote,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: song.albumArtUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.trackName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artistName,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added by ${Helpers.getBetterDisplayName(song.addedByDisplayName, null)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (song.moodTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: song.moodTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        onPressed: onUpvote,
                        color: AppTheme.primaryColor,
                      ),
                      Text(
                        '${song.voteScore}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 20),
                        onPressed: onDownvote,
                        color: AppTheme.errorColor,
                      ),
                    ],
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: AppTheme.errorColor,
                      tooltip: 'Delete song',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}