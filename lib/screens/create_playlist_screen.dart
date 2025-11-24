import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/providers.dart';
import '../services/cloudinary_service.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';

class CreatePlaylistScreen extends ConsumerStatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  ConsumerState<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends ConsumerState<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String? _coverImageUrl;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final imageUrl = await _cloudinaryService.uploadPlaylistCover();
      if (imageUrl != null && mounted) {
        setState(() {
          _coverImageUrl = imageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _createPlaylist() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProviderInstance).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a playlist')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final playlistId = await ref.read(playlistProviderInstance.notifier).createPlaylist(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        coverImage: _coverImageUrl,
        creatorId: user.uid,
        creatorName: Helpers.getBetterDisplayName(user.displayName, user.email),
        creatorProfilePicture: user.profilePicture,
        isPublic: _isPublic,
      );

      if (mounted) {
        if (playlistId != null) {
          Navigator.pop(context);
          AppRoutes.navigateToPlaylist(context, playlistId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create playlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              Center(
                child: GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: _coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _coverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate,
                                size: 60,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Cover',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              ),
              const SizedBox(height: 32),
              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Playlist Name',
                prefixIcon: Icons.queue_music,
                validator: Validators.validateName,
                hint: 'Enter playlist name',
              ),
              const SizedBox(height: 16),
              // Description Field
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                prefixIcon: Icons.description,
                maxLines: 3,
                hint: 'Tell us about this playlist...',
              ),
              const SizedBox(height: 24),
              // Public Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Make Public'),
                  subtitle: Text(
                    'Anyone can find and join this playlist',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Create Button
              CustomButton(
                text: 'Create Playlist',
                onPressed: _isLoading ? null : _createPlaylist,
                isLoading: _isLoading,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
