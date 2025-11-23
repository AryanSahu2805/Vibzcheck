import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/providers.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _showSpotifyOption = false;
  bool _connectingSpotify = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = ref.read(authProviderInstance.notifier);
    bool success;

    if (_isLogin) {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      // Show Spotify option after successful signup
      if (success && mounted) {
        setState(() => _showSpotifyOption = true);
      }
    }

    if (success && mounted && _isLogin) {
      AppRoutes.navigateToHome(context);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authProviderInstance).error ?? 'Error')),
      );
    }
  }

  Future<void> _connectSpotify() async {
    setState(() => _connectingSpotify = true);
    final authProvider = ref.read(authProviderInstance.notifier);
    try {
      final success = await authProvider.connectSpotify();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Spotify connected successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Navigate to home after Spotify connection
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            AppRoutes.navigateToHome(context);
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(authProviderInstance).error ?? 'Failed to connect Spotify'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _connectingSpotify = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _connectingSpotify = false);
      }
    }
  }

  void _skipSpotify() {
    AppRoutes.navigateToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProviderInstance);

    // Show Spotify connection screen after signup
    if (_showSpotifyOption && !_isLogin) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                const Icon(Icons.music_note, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Connect Spotify',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enhance your music experience by connecting your Spotify account. This allows you to search and add songs from Spotify to your playlists.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'Connect Spotify',
                  onPressed: _connectSpotify,
                  isLoading: _connectingSpotify,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Skip for Now',
                  onPressed: _skipSpotify,
                  variant: ButtonVariant.outlined,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.music_note, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Vibzcheck',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (!_isLogin)
                  CustomTextField(
                    controller: _nameController,
                    label: 'Display Name',
                    prefixIcon: Icons.person,
                    validator: Validators.validateName,
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: _isLogin ? 'Sign In' : 'Sign Up',
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Sign In',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
