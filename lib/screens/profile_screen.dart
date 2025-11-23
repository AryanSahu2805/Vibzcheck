import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../models/playlist_model.dart';
import '../widgets/playlist_card.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProviderInstance);
    final currentUser = authState.currentUser;
    final isCurrentUser = widget.userId == null || widget.userId == currentUser?.uid;

    if (currentUser == null && isCurrentUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 240,
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: isCurrentUser ? _updateProfilePicture : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.surfaceColor,
                                backgroundImage: currentUser?.profilePicture != null
                                    ? CachedNetworkImageProvider(currentUser!.profilePicture!)
                                    : null,
                                child: currentUser?.profilePicture == null
                                    ? Text(
                                        currentUser?.initials ?? 'U',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isCurrentUser)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.backgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          currentUser?.displayName ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Email - with proper text wrapping and overflow handling
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              currentUser?.email ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => AppRoutes.navigateToSettings(context),
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
                  if (isCurrentUser) ...[
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Playlists', '${currentUser?.playlistIds.length ?? 0}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Joined', 'Recently'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  // My Playlists Section
                  Text(
                    isCurrentUser ? 'My Playlists' : 'Playlists',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Playlists List
          StreamBuilder<List<PlaylistModel>>(
            stream: ref.read(firestoreServiceProvider).getUserPlaylists(
              widget.userId ?? currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final playlists = snapshot.data ?? [];

              if (playlists.isEmpty) {
                return SliverFillRemaining(
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
                          'No playlists yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCurrentUser
                              ? 'Create your first playlist!'
                              : 'This user has no playlists',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Create Playlist',
                            icon: Icons.add,
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.createPlaylist);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PlaylistCard(
                        playlist: playlists[index],
                        onTap: () {
                          AppRoutes.navigateToPlaylist(context, playlists[index].id);
                        },
                      ),
                    );
                  },
                  childCount: playlists.length,
                ),
              );
            },
          ),
          // Sign Out Button (if current user)
          if (isCurrentUser)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: 'Sign Out',
                  icon: Icons.logout,
                  variant: ButtonVariant.outlined,
                  color: AppTheme.errorColor,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await _authService.signOut();
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      AppRoutes.navigateToAuth(context);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
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

  Future<void> _updateProfilePicture() async {
    try {
      final imageUrl = await _cloudinaryService.uploadProfilePicture();
      if (imageUrl != null && mounted) {
        final user = ref.read(authProviderInstance).currentUser;
        if (user != null) {
          await _authService.updateProfile(profilePicture: imageUrl);
          ref.read(authProviderInstance.notifier).refreshUser();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }
}
