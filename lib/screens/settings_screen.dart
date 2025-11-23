import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  
  bool _showPasswordSection = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authProviderInstance).currentUser;
    _displayNameController = TextEditingController(text: currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePicture() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final uploadedUrl = await _cloudinaryService.uploadImage(
        pickedFile.path,
        folder: 'vibzcheck/profiles',
      );

      if (!mounted) return;

      await _authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        profilePicture: uploadedUrl,
      );

      final authProvider = ref.read(authProviderInstance.notifier);
      await authProvider.refreshUser();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile picture updated')),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _authService.updateProfile(
        displayName: _displayNameController.text.trim(),
      );

      final authProvider = ref.read(authProviderInstance.notifier);
      await authProvider.refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Display name updated')),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _authService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Password updated')),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isLoading = false;
        _showPasswordSection = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authProvider = ref.read(authProviderInstance.notifier);
      await authProvider.signOut();

      if (!mounted) return;

      AppRoutes.navigateToAuth(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProviderInstance);
    final currentUser = authState.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Section
                  _buildSectionHeader('Profile'),
                  const SizedBox(height: 16),
                  
                  // Profile Picture
                  Center(
                    child: GestureDetector(
                      onTap: _updateProfilePicture,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.surfaceColor,
                            backgroundImage: currentUser.profilePicture != null
                                ? NetworkImage(currentUser.profilePicture!)
                                : null,
                            child: currentUser.profilePicture == null
                                ? Text(
                                    currentUser.initials,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
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
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display Name
                  CustomTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    prefixIcon: Icons.person,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Update Display Name',
                    onPressed: _updateDisplayName,
                  ),
                  const SizedBox(height: 32),

                  // Email Section
                  _buildSectionHeader('Email'),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email,
                    enabled: false,
                    suffixIcon: const Tooltip(
                      message: 'Email cannot be changed yet',
                      child: Icon(Icons.info, color: AppTheme.textTertiary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Security Section
                  _buildSectionHeader('Security'),
                  const SizedBox(height: 16),
                  
                  if (!_showPasswordSection)
                    CustomButton(
                      text: 'Change Password',
                      onPressed: () => setState(() => _showPasswordSection = true),
                      variant: ButtonVariant.outlined,
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          prefixIcon: Icons.lock,
                          obscureText: _obscureCurrentPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                              () =>
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          prefixIcon: Icons.lock_open,
                          obscureText: _obscureNewPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                              () =>
                                  _obscureNewPassword = !_obscureNewPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Update Password',
                                onPressed: _updatePassword,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                onPressed: () => setState(
                                  () => _showPasswordSection = false,
                                ),
                                variant: ButtonVariant.outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // Danger Zone
                  _buildSectionHeader('Danger Zone', isDangerous: true),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Logout',
                    onPressed: _logout,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDangerous = false}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: isDangerous ? Colors.red : AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
