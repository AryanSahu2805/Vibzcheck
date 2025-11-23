import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/spotify_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SpotifyService _spotifyService = SpotifyService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  
  AuthProvider() {
    _init();
  }
  
  Future<void> _init() async {
    try {
      _authService.authStateChanges.listen((User? user) async {
        try {
          if (user != null) {
            _currentUser = await _authService.getUserData(user.uid);
            notifyListeners();
          } else {
            _currentUser = null;
            notifyListeners();
          }
        } catch (e) {
          Logger.info('❌ Error in auth state listener: $e');
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
      Logger.info('❌ Error initializing auth provider: $e');
      _currentUser = null;
      notifyListeners();
    }
  }
  
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      Logger.info('Attempting sign in for: $email');
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (_currentUser == null) {
        Logger.warning('Sign in returned null user');
        _error = 'Failed to sign in. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      Logger.success('Sign in successful for: ${_currentUser!.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      Logger.error('Sign in error', e, st);
      
      // Provide user-friendly error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('PigeonUserDetails') || 
          errorMessage.contains('type cast') ||
          errorMessage.contains('subtype')) {
        errorMessage = 'Login error. Please try again or contact support.';
        Logger.error('Type casting error detected - this may be a data format issue', e, st);
      } else if (errorMessage.contains('user-not-found')) {
        errorMessage = 'Email not registered. Please sign up first.';
      } else if (errorMessage.contains('wrong-password') || errorMessage.contains('invalid-credential')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      }
      
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
    _spotifyService.clearToken();
    _currentUser = null;
    notifyListeners();
  }
  
  Future<bool> connectSpotify() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      Logger.info('Connecting to Spotify...');
      final success = await _spotifyService.authorize();
      
      if (success) {
        Logger.info('Spotify authorization successful, fetching user profile...');
        final profile = await _spotifyService.getUserProfile();
        if (profile != null) {
          Logger.info('Linking Spotify account to user...');
          await _authService.linkSpotifyAccount(
            spotifyId: profile['id'],
            spotifyData: profile,
          );
          if (_currentUser != null) {
            _currentUser = await _authService.getUserData(_currentUser!.uid);
          }
          _isLoading = false;
          notifyListeners();
          Logger.success('Spotify account linked successfully!');
          return true;
        } else {
          Logger.warning('Failed to fetch Spotify user profile');
          _error = 'Failed to fetch Spotify profile';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        Logger.warning('Spotify authorization failed');
        _error = 'Failed to authorize with Spotify. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      Logger.error('Error connecting Spotify', e, st);
      _error = 'Failed to connect Spotify: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateProfile({
    String? displayName,
    String? profilePicture,
  }) async {
    try {
      await _authService.updateProfile(
        displayName: displayName,
        profilePicture: profilePicture,
      );
      _currentUser = await _authService.getUserData(_currentUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      _currentUser = await _authService.getUserData(_currentUser!.uid);
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}