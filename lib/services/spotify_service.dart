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
      
      // Launch Spotify authorization
      final url = Uri.parse(authorizationUrl);
      Logger.debug('Authorization URL: $authorizationUrl');
      
      if (await canLaunchUrl(url)) {
        Logger.info('Launching Spotify authorization URL...');
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Wait for callback
        Logger.info('Waiting for authorization callback...');
        final code = await _waitForAuthorizationCode();
        if (code != null) {
          Logger.info('Authorization code received, exchanging for access token...');
          return await _exchangeCodeForToken(code);
        } else {
          Logger.warning('No authorization code received');
          return false;
        }
      } else {
        Logger.error('Could not launch Spotify authorization URL');
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
      // Get the initial link if app was opened with one
      final uri = await _appLinks.getInitialLink();
      if (uri != null && uri.queryParameters.containsKey('code')) {
        return uri.queryParameters['code'];
      }
      
      // Listen for incoming links
      await for (final uri in _appLinks.uriLinkStream) {
        if (uri.queryParameters.containsKey('code')) {
          return uri.queryParameters['code'];
        }
      }
    } catch (e) {
      Logger.info('❌ Authorization code error: $e');
    }
    return null;
  }
  
  // Exchange code for access token
  Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final credentials = base64Encode(
        utf8.encode('${AppConstants.spotifyClientId}:${AppConstants.spotifyClientSecret}'),
      );
      
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConstants.spotifyRedirectUri,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in']),
        );
        return true;
      }
      
      Logger.info('❌ Token exchange failed: ${response.body}');
      return false;
    } catch (e) {
      Logger.info('❌ Token exchange error: $e');
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