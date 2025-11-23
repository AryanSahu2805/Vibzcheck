import 'dart:async';
import 'dart:convert';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../config/constants.dart';

class SpotifyService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  final _appLinks = AppLinks();
  
  // Check if Spotify is configured (REQUIRED)
  bool get isConfigured {
    final clientId = AppConstants.spotifyClientId;
    final clientSecret = AppConstants.spotifyClientSecret;
    final redirectUri = AppConstants.spotifyRedirectUri;
    
    Logger.debug('Spotify Config Check:');
    Logger.debug('  CLIENT_ID: ${clientId.isNotEmpty ? '✓ Present' : '✗ Missing'}');
    Logger.debug('  CLIENT_SECRET: ${clientSecret.isNotEmpty ? '✓ Present' : '✗ Missing'}');
    Logger.debug('  REDIRECT_URI: ${redirectUri.isNotEmpty ? '✓ Present ($redirectUri)' : '✗ Missing'}');
    
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw Exception(
        'Spotify credentials not configured. '
        'Please set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET in .env file. '
        'Current values: CLIENT_ID="${clientId.isEmpty ? '[EMPTY]' : '[SET]'}", '
        'CLIENT_SECRET="${clientSecret.isEmpty ? '[EMPTY]' : '[SET]'}"'
      );
    }
    return true;
  }
  
  // Authorization URL
  String get authorizationUrl {
    isConfigured; // Validate credentials
    final scopes = AppConstants.spotifyScopes.join('%20');
    return '${AppConstants.spotifyAuthUrl}'
        '?client_id=${AppConstants.spotifyClientId}'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(AppConstants.spotifyRedirectUri)}'
        '&scope=$scopes';
  }
  
  // Authorize with Spotify (REQUIRED)
  Future<bool> authorize() async {
    try {
      isConfigured; // Validate credentials
      Logger.info('Starting Spotify authorization...');
      
      // Clear any existing token
      clearToken();
      
      // Launch Spotify authorization
      final url = Uri.parse(authorizationUrl);
      Logger.debug('Authorization URL: $authorizationUrl');
      Logger.debug('Client ID: ${AppConstants.spotifyClientId}');
      Logger.debug('Redirect URI: ${AppConstants.spotifyRedirectUri}');
      
      // Try to launch URL - don't rely on canLaunchUrl check
      Logger.info('Launching Spotify authorization URL...');
      try {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          Logger.error('Failed to launch authorization URL');
          return false;
        }
      } catch (e) {
        Logger.error('Error launching URL: $e', e);
        // Try alternative method
        try {
          await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        } catch (e2) {
          Logger.error('Failed to launch URL with both methods', e2);
          return false;
        }
      }
      
      // Wait for callback
      Logger.info('Waiting for authorization callback...');
      final code = await _waitForAuthorizationCode();
      if (code != null && code.isNotEmpty) {
        Logger.info('Authorization code received, exchanging for access token...');
        final success = await _exchangeCodeForToken(code);
        if (success) {
          Logger.success('Spotify authorization completed successfully!');
        }
        return success;
      } else {
        Logger.warning('No authorization code received or code is empty');
        return false;
      }
    } catch (e, st) {
      Logger.error('Spotify auth error', e, st);
      return false;
    }
  }
  
  // Wait for authorization code from deep link
  Future<String?> _waitForAuthorizationCode() async {
    try {
      Logger.debug('Waiting for authorization callback...');
      
      // Get the initial link if app was opened with one
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        Logger.debug('Initial link received: $initialUri');
        if (initialUri.queryParameters.containsKey('code')) {
          Logger.success('Authorization code found in initial link');
          return initialUri.queryParameters['code'];
        }
        if (initialUri.queryParameters.containsKey('error')) {
          Logger.error('Authorization error: ${initialUri.queryParameters['error']}');
          return null;
        }
      }
      
      // Listen for incoming links with timeout
      Logger.debug('Listening for deep link callback...');
      final completer = Completer<String?>();
      StreamSubscription? subscription;
      Timer? timeoutTimer;
      
      subscription = _appLinks.uriLinkStream.listen(
        (uri) {
          Logger.debug('Deep link received: $uri');
          if (uri.queryParameters.containsKey('code')) {
            Logger.success('Authorization code received: ${uri.queryParameters['code']?.substring(0, 10)}...');
            subscription?.cancel();
            timeoutTimer?.cancel();
            completer.complete(uri.queryParameters['code']);
          } else if (uri.queryParameters.containsKey('error')) {
            Logger.error('Authorization error: ${uri.queryParameters['error']}');
            subscription?.cancel();
            timeoutTimer?.cancel();
            completer.complete(null);
          }
        },
        onError: (error) {
          Logger.error('Deep link stream error', error);
          subscription?.cancel();
          timeoutTimer?.cancel();
          completer.complete(null);
        },
      );
      
      // Set timeout (2 minutes)
      timeoutTimer = Timer(const Duration(minutes: 2), () {
        Logger.warning('Authorization timeout - no callback received');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      return await completer.future;
    } catch (e, st) {
      Logger.error('Authorization code error', e, st);
      return null;
    }
  }
  
  // Exchange code for access token
  Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final credentials = base64Encode(
        utf8.encode('${AppConstants.spotifyClientId}:${AppConstants.spotifyClientSecret}'),
      );
      
      final redirectUri = AppConstants.spotifyRedirectUri;
      Logger.debug('Exchanging code for token...');
      Logger.debug('Redirect URI: $redirectUri');
      
      // Encode body properly
      final body = Uri(
        queryParameters: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      ).query;
      
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      Logger.debug('Token exchange response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        Logger.success('Spotify authorization successful!');
        return true;
      }
      
      Logger.error('Token exchange failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e, st) {
      Logger.error('Token exchange error', e, st);
      return false;
    }
  }
  
  // Check if token is valid
  bool get isAuthorized {
    return _accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!);
  }
  
  // Search tracks (REQUIRED feature)
  Future<List<Map<String, dynamic>>> searchTracks(String query, {int limit = 20}) async {
    try {
      isConfigured; // Validate credentials
      if (!isAuthorized) {
        throw Exception('Not authorized with Spotify. Please connect your Spotify account first.');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['tracks']['items'] as List;
        return tracks.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      Logger.info('❌ Search tracks error: $e');
      return [];
    }
  }
  
  // Get track details
  Future<Map<String, dynamic>?> getTrack(String trackId) async {
    try {
      if (!isAuthorized) {
        throw Exception('Not authorized');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/tracks/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      Logger.info('❌ Get track error: $e');
      return null;
    }
  }
  
  // Get audio features (for mood tagging)
  Future<Map<String, dynamic>?> getAudioFeatures(String trackId) async {
    try {
      if (!isAuthorized) {
        throw Exception('Not authorized');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/audio-features/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      Logger.info('❌ Get audio features error: $e');
      return null;
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isAuthorized) {
        throw Exception('Not authorized');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/me'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      Logger.info('❌ Get user profile error: $e');
      return null;
    }
  }
  
  // Get user's top tracks
  Future<List<Map<String, dynamic>>> getTopTracks({int limit = 20}) async {
    try {
      if (!isAuthorized) {
        throw Exception('Not authorized');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/me/top/tracks?limit=$limit&time_range=medium_term'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      Logger.info('❌ Get top tracks error: $e');
      return [];
    }
  }
  
  // Determine mood tags from audio features
  List<String> getMoodTags(Map<String, dynamic> audioFeatures) {
    final List<String> tags = [];
    
    final energy = audioFeatures['energy'] ?? 0.0;
    final valence = audioFeatures['valence'] ?? 0.0;
    final danceability = audioFeatures['danceability'] ?? 0.0;
    final instrumentalness = audioFeatures['instrumentalness'] ?? 0.0;
    
    // Check each mood
    AppConstants.moodTags.forEach((mood, criteria) {
      bool matches = true;
      
      if (criteria.containsKey('minEnergy') && energy < criteria['minEnergy']) {
        matches = false;
      }
      if (criteria.containsKey('maxEnergy') && energy > criteria['maxEnergy']) {
        matches = false;
      }
      if (criteria.containsKey('minValence') && valence < criteria['minValence']) {
        matches = false;
      }
      if (criteria.containsKey('maxValence') && valence > criteria['maxValence']) {
        matches = false;
      }
      if (criteria.containsKey('minDanceability') && danceability < criteria['minDanceability']) {
        matches = false;
      }
      if (criteria.containsKey('minInstrumentalness') && instrumentalness < criteria['minInstrumentalness']) {
        matches = false;
      }
      
      if (matches) {
        tags.add(mood);
      }
    });
    
    return tags;
  }
  
  // Clear token (logout)
  void clearToken() {
    _accessToken = null;
    _tokenExpiry = null;
  }
}