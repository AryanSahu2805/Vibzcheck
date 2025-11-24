import 'dart:async';
import 'dart:convert';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class SpotifyService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  final _appLinks = AppLinks();
  bool _isAuthorizing = false; // Track if we're in an active authorization flow
  
  bool _tokenLoadAttempted = false;
  
  // Initialize and load persisted token
  SpotifyService() {
    _loadToken();
  }
  
  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    if (_tokenLoadAttempted) return; // Prevent multiple loads
    _tokenLoadAttempted = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('spotify_access_token');
      final expiryStr = prefs.getString('spotify_token_expiry');
      
      if (token != null && expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isBefore(expiry)) {
          _accessToken = token;
          _tokenExpiry = expiry;
          Logger.info('✅ Loaded persisted Spotify token (expires: ${expiry.toIso8601String()})');
        } else {
          Logger.info('⚠️ Persisted Spotify token expired, clearing...');
          await _clearPersistedToken();
        }
      } else {
        Logger.debug('No persisted token found');
      }
    } catch (e) {
      Logger.warning('Could not load persisted token: $e');
    }
  }
  
  // Ensure token is loaded before use
  Future<void> ensureTokenLoaded() async {
    if (!_tokenLoadAttempted) {
      await _loadToken();
    }
  }
  
  // Save token to SharedPreferences
  Future<void> _saveToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null && _tokenExpiry != null) {
        await prefs.setString('spotify_access_token', _accessToken!);
        await prefs.setString('spotify_token_expiry', _tokenExpiry!.toIso8601String());
        Logger.info('✅ Persisted Spotify token');
      }
    } catch (e) {
      Logger.warning('Could not persist token: $e');
    }
  }
  
  // Clear persisted token
  Future<void> _clearPersistedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('spotify_access_token');
      await prefs.remove('spotify_token_expiry');
    } catch (e) {
      Logger.warning('Could not clear persisted token: $e');
    }
  }
  
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
      
      // Check if already authorized
      if (isAuthorized) {
        Logger.info('✅ Already authorized with Spotify');
        return true;
      }
      
      // Prevent multiple simultaneous authorization attempts
      if (_isAuthorizing) {
        Logger.warning('Authorization already in progress');
        return false;
      }
      
      Logger.info('Starting Spotify authorization...');
      _isAuthorizing = true;
      
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
      _isAuthorizing = false; // Reset flag
      
      if (code != null && code.isNotEmpty) {
        Logger.info('Authorization code received, exchanging for access token...');
        final success = await _exchangeCodeForToken(code);
        if (success) {
          Logger.success('Spotify authorization completed successfully!');
          await _saveToken(); // Persist the token
        }
        return success;
      } else {
        Logger.warning('No authorization code received or code is empty');
        return false;
      }
    } catch (e, st) {
      _isAuthorizing = false; // Reset flag on error
      Logger.error('Spotify auth error', e, st);
      return false;
    }
  }
  
  // Wait for authorization code from deep link
  Future<String?> _waitForAuthorizationCode() async {
    try {
      Logger.debug('Waiting for authorization callback...');
      
      // Don't use getInitialLink() - it returns old codes that have already been used
      // Only listen to the stream for NEW authorization callbacks
      
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
        
        // Also handle refresh token if provided
        final refreshToken = data['refresh_token'] as String?;
        if (refreshToken != null) {
          await _saveRefreshToken(refreshToken);
        }
        
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
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }
    
    // Check if token is expired (with 5 minute buffer)
    final now = DateTime.now();
    final expiryWithBuffer = _tokenExpiry!.subtract(const Duration(minutes: 5));
    
    if (now.isAfter(expiryWithBuffer)) {
      Logger.warning('Spotify token expired or expiring soon');
      // Try to refresh if we have a refresh token
      return false;
    }
    
    return true;
  }
  
  // Save refresh token
  Future<void> _saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_refresh_token', refreshToken);
    } catch (e) {
      Logger.warning('Could not save refresh token: $e');
    }
  }
  
  // Get refresh token
  Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('spotify_refresh_token');
    } catch (e) {
      return null;
    }
  }
  
  // Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        Logger.warning('No refresh token available');
        return false;
      }
      
      Logger.info('Refreshing Spotify access token...');
      
      final credentials = base64Encode(
        utf8.encode('${AppConstants.spotifyClientId}:${AppConstants.spotifyClientSecret}'),
      );
      
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: Uri(
          queryParameters: {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          },
        ).query,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        // Save new token
        await _saveToken();
        
        Logger.success('✅ Spotify token refreshed successfully');
        return true;
      }
      
      Logger.error('Token refresh failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e, st) {
      Logger.error('Token refresh error', e, st);
      return false;
    }
  }
  
  // Ensure token is valid, refresh if needed
  Future<void> ensureAuthorized() async {
    await ensureTokenLoaded();
    
    if (!isAuthorized) {
      Logger.info('Token expired or missing, attempting refresh...');
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        throw Exception('Spotify authorization expired. Please reconnect your Spotify account.');
      }
    }
  }
  
  // Search tracks (REQUIRED feature) with retry logic
  Future<List<Map<String, dynamic>>> searchTracks(String query, {int limit = 20, int maxRetries = 2}) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        // Ensure token is valid and refreshed if needed
        await ensureAuthorized();
        
        isConfigured; // Validate credentials
        
        Logger.debug('Searching for: "$query" (attempt ${attempt + 1}/${maxRetries + 1})');
        Logger.debug('Using access token: ${_accessToken?.substring(0, 20)}...');
        
        final url = '${AppConstants.spotifyApiUrl}/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit';
        Logger.debug('Search URL: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
        
        Logger.debug('Search response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final tracks = data['tracks']?['items'] as List?;
          
          if (tracks == null || tracks.isEmpty) {
            Logger.info('No tracks found for query: "$query"');
            return [];
          }
          
          Logger.success('Found ${tracks.length} tracks for query: "$query"');
          return tracks.cast<Map<String, dynamic>>();
        } else if (response.statusCode == 401) {
          Logger.error('Unauthorized (401) - token may be expired');
          
          // Try to refresh token on first attempt
          if (attempt == 0) {
            Logger.info('Attempting to refresh token...');
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              attempt++;
              continue; // Retry with new token
            }
          }
          
          // Clear token and force re-authorization
          await clearToken();
          throw Exception('Spotify authorization expired. Please reconnect your Spotify account.');
        } else if (response.statusCode == 403) {
          final errorBody = response.body;
          Logger.warning('Forbidden (403) - attempt ${attempt + 1}/${maxRetries + 1}');
          
          // Check if it's a rate limit issue (retry) or user registration issue
          if (errorBody.contains('rate limit') || errorBody.contains('too many requests')) {
            if (attempt < maxRetries) {
              // Rate limiting - wait and retry with exponential backoff
              final waitTime = Duration(milliseconds: 500 * (attempt + 1));
              Logger.info('Rate limited, waiting ${waitTime.inMilliseconds}ms before retry...');
              await Future.delayed(waitTime);
              attempt++;
              continue;
            }
            throw Exception('Spotify rate limit exceeded. Please wait a moment and try again.');
          }
          
          // User registration issue - don't retry
          Logger.error('Forbidden (403) - user may not be registered in Spotify Developer Dashboard');
          String errorMessage = 'Access denied by Spotify. ';
          
          if (errorBody.contains('user may not be registered')) {
            errorMessage += 'Your Spotify account needs to be added to the allowed users list in the Spotify Developer Dashboard. Please contact the app developer or add your email in the dashboard settings.';
          } else {
            errorMessage += 'Please check your Spotify Developer Dashboard settings. The app may be in development mode and requires user registration.';
          }
          
          throw Exception(errorMessage);
        } else {
          Logger.error('Search failed with status ${response.statusCode}: ${response.body}');
          throw Exception('Failed to search: ${response.statusCode}');
        }
      } catch (e, st) {
        if (attempt < maxRetries && e.toString().contains('rate limit')) {
          // Retry on rate limit errors
          final waitTime = Duration(milliseconds: 500 * (attempt + 1));
          Logger.info('Retrying after ${waitTime.inMilliseconds}ms...');
          await Future.delayed(waitTime);
          attempt++;
          continue;
        }
        
        Logger.error('Search tracks error', e, st);
        rethrow; // Re-throw so the UI can handle it
      }
    }
    
    throw Exception('Failed to search after ${maxRetries + 1} attempts');
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
      // Ensure token is authorized before making request
      await ensureAuthorized();
      
      if (!isAuthorized) {
        Logger.warning('⚠️ Not authorized to get audio features');
        return null;
      }
      
      Logger.debug('Getting audio features for track: $trackId');
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/audio-features/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        final features = jsonDecode(response.body) as Map<String, dynamic>;
        Logger.success('✅ Got audio features for track: $trackId');
        return features;
      } else if (response.statusCode == 401) {
        Logger.warning('⚠️ Unauthorized (401) - token may be expired');
        // Try to refresh token
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry once
          final retryResponse = await http.get(
            Uri.parse('${AppConstants.spotifyApiUrl}/audio-features/$trackId'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          );
          if (retryResponse.statusCode == 200) {
            return jsonDecode(retryResponse.body) as Map<String, dynamic>;
          }
        }
        return null;
      }
      
      Logger.warning('⚠️ Failed to get audio features: ${response.statusCode}');
      return null;
    } catch (e) {
      Logger.error('❌ Get audio features error', e, null);
      return null;
    }
  }
  
  // Get track details (useful for getting preview URL if missing from search)
  Future<Map<String, dynamic>?> getTrackDetails(String trackId) async {
    try {
      await ensureAuthorized();
      
      if (!isAuthorized) {
        Logger.warning('⚠️ Not authorized to get track details');
        return null;
      }
      
      Logger.debug('Getting track details for: $trackId');
      
      final response = await http.get(
        Uri.parse('${AppConstants.spotifyApiUrl}/tracks/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      
      if (response.statusCode == 200) {
        final track = jsonDecode(response.body) as Map<String, dynamic>;
        Logger.success('✅ Got track details for: $trackId');
        return track;
      } else if (response.statusCode == 401) {
        Logger.warning('⚠️ Unauthorized (401) - token may be expired');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.get(
            Uri.parse('${AppConstants.spotifyApiUrl}/tracks/$trackId'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          );
          if (retryResponse.statusCode == 200) {
            return jsonDecode(retryResponse.body) as Map<String, dynamic>;
          }
        }
        return null;
      }
      
      Logger.warning('⚠️ Failed to get track details: ${response.statusCode}');
      return null;
    } catch (e) {
      Logger.error('❌ Get track details error', e, null);
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
  
  // Fallback: Determine mood tags from track metadata (name, artist, genre)
  List<String> getMoodTagsFromMetadata({
    required String trackName,
    required String artistName,
    String? albumName,
    List<String>? genres,
  }) {
    final List<String> tags = [];
    final text = '${trackName.toLowerCase()} ${artistName.toLowerCase()} ${albumName?.toLowerCase() ?? ''} ${genres?.join(' ').toLowerCase() ?? ''}';
    
    // Energetic keywords
    final energeticKeywords = [
      'energy', 'energetic', 'power', 'powerful', 'intense', 'intensity', 'fast', 'speed',
      'rock', 'metal', 'punk', 'hardcore', 'thrash', 'aggressive', 'loud', 'explosive',
      'fire', 'burn', 'blast', 'crash', 'bang', 'boom', 'wild', 'furious', 'rage',
      'adrenaline', 'pump', 'boost', 'charge', 'turbo', 'nitro', 'thunder', 'lightning'
    ];
    
    // Chill keywords
    final chillKeywords = [
      'chill', 'relax', 'calm', 'peaceful', 'serene', 'ambient', 'ambient', 'lo-fi',
      'lofi', 'smooth', 'soft', 'gentle', 'mellow', 'laid back', 'easy', 'quiet',
      'zen', 'meditation', 'yoga', 'spa', 'rain', 'ocean', 'waves', 'nature',
      'acoustic', 'unplugged', 'minimal', 'subtle', 'breeze', 'whisper'
    ];
    
    // Happy keywords
    final happyKeywords = [
      'happy', 'joy', 'joyful', 'cheerful', 'bright', 'sunny', 'smile', 'laugh',
      'fun', 'funny', 'party', 'celebrate', 'celebration', 'festival', 'carnival',
      'upbeat', 'positive', 'optimistic', 'uplifting', 'inspiring', 'motivational',
      'summer', 'beach', 'vacation', 'holiday', 'birthday', 'wedding', 'dance'
    ];
    
    // Sad keywords
    final sadKeywords = [
      'sad', 'sorrow', 'sorrowful', 'melancholy', 'depressed', 'lonely', 'alone',
      'heartbreak', 'breakup', 'tears', 'cry', 'crying', 'pain', 'hurt', 'ache',
      'miss', 'missing', 'goodbye', 'farewell', 'lost', 'empty', 'dark', 'gloomy',
      'rainy', 'winter', 'autumn', 'fall', 'blue', 'blues', 'ballad', 'slow'
    ];
    
    // Party keywords
    final partyKeywords = [
      'party', 'club', 'dance', 'dancing', 'disco', 'house', 'edm', 'electronic',
      'techno', 'trance', 'rave', 'festival', 'celebration', 'celebration', 'night',
      'nightlife', 'dj', 'mix', 'remix', 'beat', 'bass', 'drop', 'banger',
      'anthem', 'hype', 'turn up', 'turnt', 'lit', 'fire', 'hot', 'groove'
    ];
    
    // Focus keywords
    final focusKeywords = [
      'focus', 'study', 'work', 'productivity', 'concentration', 'instrumental',
      'classical', 'piano', 'violin', 'orchestra', 'symphony', 'jazz', 'smooth jazz',
      'background', 'ambient', 'atmospheric', 'cinematic', 'soundtrack', 'score',
      'minimal', 'simple', 'clean', 'pure', 'acoustic', 'unplugged', 'solo'
    ];
    
    // Check for energetic
    if (energeticKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('energetic');
    }
    
    // Check for chill
    if (chillKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('chill');
    }
    
    // Check for happy
    if (happyKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('happy');
    }
    
    // Check for sad
    if (sadKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('sad');
    }
    
    // Check for party
    if (partyKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('party');
    }
    
    // Check for focus
    if (focusKeywords.any((keyword) => text.contains(keyword))) {
      tags.add('focus');
    }
    
    // Genre-based tagging (if genres are available)
    if (genres != null && genres.isNotEmpty) {
      final genreText = genres.join(' ').toLowerCase();
      
      // Energetic genres
      if (genreText.contains('rock') || genreText.contains('metal') || 
          genreText.contains('punk') || genreText.contains('hardcore')) {
        if (!tags.contains('energetic')) tags.add('energetic');
      }
      
      // Chill genres
      if (genreText.contains('ambient') || genreText.contains('lofi') || 
          genreText.contains('chill') || genreText.contains('acoustic')) {
        if (!tags.contains('chill')) tags.add('chill');
      }
      
      // Party genres
      if (genreText.contains('dance') || genreText.contains('edm') || 
          genreText.contains('electronic') || genreText.contains('house') ||
          genreText.contains('techno') || genreText.contains('pop')) {
        if (!tags.contains('party')) tags.add('party');
      }
      
      // Focus genres
      if (genreText.contains('classical') || genreText.contains('jazz') || 
          genreText.contains('instrumental') || genreText.contains('piano')) {
        if (!tags.contains('focus')) tags.add('focus');
      }
      
      // Happy genres
      if (genreText.contains('pop') || genreText.contains('indie pop') || 
          genreText.contains('folk') || genreText.contains('country')) {
        if (!tags.contains('happy')) tags.add('happy');
      }
      
      // Sad genres
      if (genreText.contains('blues') || genreText.contains('soul') || 
          genreText.contains('ballad') || genreText.contains('r&b')) {
        if (!tags.contains('sad')) tags.add('sad');
      }
    }
    
    // If no tags found, add a default based on duration or other heuristics
    if (tags.isEmpty) {
      // Default to 'chill' if we can't determine anything
      tags.add('chill');
    }
    
    // Limit to 3 tags max to keep it clean
    return tags.take(3).toList();
  }
  
  // Clear token (logout)
  Future<void> clearToken() async {
    _accessToken = null;
    _tokenExpiry = null;
    await _clearPersistedToken();
    Logger.info('✅ Spotify token cleared');
  }
}