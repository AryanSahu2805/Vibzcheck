import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/playlist_model.dart';
import '../providers/providers.dart';
import '../utils/helpers.dart';
import '../widgets/playlist_card.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _shareCodeController = TextEditingController();

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Playlist'),
        content: TextField(
          controller: _shareCodeController,
          decoration: const InputDecoration(
            labelText: 'Share Code',
            hintText: 'Enter 6-digit code',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              
              final user = ref.read(authProviderInstance).currentUser;
              if (user == null) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final playlistId = await ref.read(playlistProviderInstance.notifier).joinPlaylist(
                shareCode: _shareCodeController.text.toUpperCase(),
                userId: user.uid,
                displayName: Helpers.getBetterDisplayName(user.displayName, user.email),
                profilePicture: user.profilePicture,
              );

              if (!mounted) return;
              
              navigator.pop();
              if (playlistId != null && mounted) {
                // ignore: use_build_context_synchronously
                AppRoutes.navigateToPlaylist(context, playlistId);
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Invalid share code')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderInstance).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => AppRoutes.navigateToProfile(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Create Playlist',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.createPlaylist,
                          ),
                          icon: Icons.add,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Join Playlist',
                          onPressed: _showJoinDialog,
                          icon: Icons.group_add,
                          variant: ButtonVariant.outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<PlaylistModel>>(
                    stream: ref.read(firestoreServiceProvider).getUserPlaylists(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final playlists = snapshot.data ?? [];

                      if (playlists.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.queue_music, size: 80, color: AppTheme.textTertiary),
                              const SizedBox(height: 16),
                              Text(
                                'No playlists yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create or join a playlist to get started',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          return PlaylistCard(
                            playlist: playlists[index],
                            onTap: () => AppRoutes.navigateToPlaylist(
                              context,
                              playlists[index].id,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
