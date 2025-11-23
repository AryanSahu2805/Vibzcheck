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
      
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
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
  
  Future<void> signOut() async {
    await _authService.signOut();
    _spotifyService.clearToken();
    _currentUser = null;
    notifyListeners();
  }
  
  Future<bool> connectSpotify() async {
    try {
      Logger.info('📱 Connecting to Spotify...');
      final success = await _spotifyService.authorize();
      Logger.debug('authorize() returned: $success');
      if (success) {
        Logger.info('Getting Spotify profile...');
        final profile = await _spotifyService.getUserProfile();
        if (profile != null) {
          Logger.info('Linking Spotify account to user...');
          await _authService.linkSpotifyAccount(
            spotifyId: profile['id'],
            spotifyData: profile,
          );
          _currentUser = await _authService.getUserData(_currentUser!.uid);
          _error = null;
          Logger.success('✅ Spotify account linked successfully');
          notifyListeners();
        } else {
          Logger.error('Could not fetch Spotify profile after authorization');
          _error = 'Could not fetch Spotify profile';
        }
      } else {
        Logger.warning('Spotify authorization failed');
        _error = 'Spotify authorization failed. Check logs for details.';
      }
      notifyListeners();
      return success;
    } catch (e, st) {
      Logger.error('connectSpotify error', e, st);
      _error = 'Connection error: $e';
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