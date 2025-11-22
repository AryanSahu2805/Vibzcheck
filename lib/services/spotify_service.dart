import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import '../config/constants.dart';

class SpotifyService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Authorization URL
  String get authorizationUrl {
    final scopes = AppConstants.spotifyScopes.join('%20');
    return '${AppConstants.spotifyAuthUrl}'
        '?client_id=${AppConstants.spotifyClientId}'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(AppConstants.spotifyRedirectUri)}'
        '&scope=$scopes';
  }
  
  // Authorize with Spotify
  Future<bool> authorize() async {
    try {
      // Launch Spotify authorization
      final url = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Wait for callback
        final code = await _waitForAuthorizationCode();
        if (code != null) {
          return await _exchangeCodeForToken(code);
        }
      }
      return false;
    } catch (e) {
      print('❌ Spotify auth error: $e');
      return false;
    }
  }
  
  // Wait for authorization code from deep link
  Future<String?> _waitForAuthorizationCode() async {
    try {
      final uri = await getInitialUri();
      if (uri != null && uri.queryParameters.containsKey('code')) {
        return uri.queryParameters['code'];
      }
      
      // Listen for incoming links
      await for (final uri in uriLinkStream) {
        if (uri.queryParameters.containsKey('code')) {
          return uri.queryParameters['code'];
        }
      }
    } catch (e) {
      print('❌ Authorization code error: $e');
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
      
      print('❌ Token exchange failed: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Token exchange error: $e');
      return false;
    }
  }
  
  // Check if token is valid
  bool get isAuthorized {
    return _accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!);
  }
  
  // Search tracks
  Future<List<Map<String, dynamic>>> searchTracks(String query, {int limit = 20}) async {
    try {
      if (!isAuthorized) {
        throw Exception('Not authorized');
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
      print('❌ Search tracks error: $e');
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
      print('❌ Get track error: $e');
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
      print('❌ Get audio features error: $e');
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
      print('❌ Get user profile error: $e');
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
      print('❌ Get top tracks error: $e');
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