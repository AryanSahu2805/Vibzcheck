# Spotify OAuth Configuration Verification Checklist

## ✅ Code-Side Configuration (Verified)

### Android Manifest
- [x] **Intent-filter registered**: `vibzcheck://callback` deep link configured in MainActivity
  - Location: `android/app/src/main/AndroidManifest.xml`
  - Activity: MainActivity (with `android:launchMode="singleTop"` for proper deep-link handling)
  - Scheme: `vibzcheck`
  - Host: `callback`
  - No separate CallbackActivity needed (app_links handles deep-linking via MainActivity)

### Constants Configuration
- [x] **spotifyRedirectUri correctly set**: `'vibzcheck://callback'`
  - Location: `lib/config/constants.dart` (line 11)
  - Type: Environment-based with fallback default
  - Fallback: `vibzcheck://callback` (matches Spotify requirement)

### Environment File
- [x] **.env file configured** (assumed from previous context)
  - Should contain:
    - `SPOTIFY_CLIENT_ID=<your-client-id>`
    - `SPOTIFY_CLIENT_SECRET=<your-client-secret>`
    - `SPOTIFY_REDIRECT_URI=vibzcheck://callback`

### Spotify Service Implementation
- [x] **Authorization flow implemented**: `lib/services/spotify_service.dart`
  - Uses app_links deep-linking (not flutter_web_auth_2)
  - launchUrl with urlScheme fallback for iOS
  - Completer-based callback waiting with 120s timeout
  - Deep-link listener via app_links StreamSubscription
  - Proper cleanup on completion

### Real-time Validation
- [x] **Token validation enhanced**: `lib/services/spotify_service.dart`
  - isAuthorized getter with 5-minute expiry buffer
  - ensureAuthorized() method for auto-refresh
  - 401 response handling clears tokens and forces re-auth
  - Applied to all API methods: searchTracks, getTrack, getAudioFeatures, getUserProfile, getTopTracks

---

## ⚠️ Spotify Developer Dashboard Configuration (Must Verify)

Before running the app, verify these settings in [Spotify Developer Dashboard](https://developer.spotify.com/dashboard):

### 1. Redirect URI
- [ ] **Application Settings** → **Redirect URIs**
  - Required URI: `vibzcheck://callback`
  - Status: Added to allowlist ✓
  - Note: This must be EXACTLY the same as configured in code

### 2. OAuth Credentials
- [ ] **Client ID** matches `SPOTIFY_CLIENT_ID` in `.env`
- [ ] **Client Secret** matches `SPOTIFY_CLIENT_SECRET` in `.env`
- [ ] Client Secret is **never committed to git** (check `.gitignore`)

### 3. Website URL (Important!)
- [ ] **Application Settings** → **Website URL**
  - Status: Can be left empty OR set to your actual website
  - ⚠️ If set, ensure it does NOT conflict with app scheme
  - Recommendation: Leave empty or set to official website (not app-related)

### 4. Request User Authorization Scopes
- [ ] Ensure these scopes are authorized:
  - `user-read-private` ✓
  - `user-read-email` ✓
  - `user-top-read` ✓
  - `playlist-read-private` ✓
  - `playlist-read-collaborative` ✓

---

## 🧪 Testing Checklist

After verifying dashboard settings, test the OAuth flow:

### 1. Initial App Launch
- [ ] Run: `flutter run` with `-v` flag for verbose logging
- [ ] Logs should show:
  - "Checking Spotify authorization..."
  - Either "User authorized with Spotify" OR "Not authorized, showing prompt"

### 2. Spotify Authorization
- [ ] Click "Connect to Spotify" button (or SearchScreen prompt)
- [ ] Logs should show:
  - "Launching Spotify authorization URL..."
  - "launchUrl succeeded"
  - "Waiting for authorization code..."

### 3. Browser Handoff
- [ ] Spotify auth URL opens in system browser
- [ ] User logs in to Spotify (if not already)
- [ ] User sees "Vibzcheck wants to access your Spotify account" prompt
- [ ] Logs may show browser navigating to `vibzcheck://callback?code=...&state=...`

### 4. App Resume & Token Exchange
- [ ] After authorization, app resumes in foreground
- [ ] Logs should show:
  - "Deep link received: vibzcheck://callback?code=..."
  - "Authorization code received: [code]"
  - "Exchanging authorization code for tokens..."
  - "Spotify authorization successful!"

### 5. API Call Success
- [ ] SearchScreen searches load successfully
- [ ] Top tracks display after authorization
- [ ] Logs show successful API calls:
  - "getUserProfile succeeded"
  - "getTopTracks succeeded"

---

## 📋 Troubleshooting Guide

### Symptom: "Deep link not received" or timeout
**Possible Causes:**
- Redirect URI in Spotify dashboard ≠ `vibzcheck://callback`
- Intent-filter not properly registered in AndroidManifest
- Deep-link scheme mismatch (check AndroidManifest)

**Fix:**
1. Verify Dashboard Redirect URI is EXACTLY `vibzcheck://callback`
2. Verify AndroidManifest intent-filter has scheme `vibzcheck` and host `callback`
3. Run `flutter clean` and rebuild

### Symptom: "Invalid redirect_uri"
**Possible Causes:**
- Mismatch between Spotify Dashboard and code configuration
- Typo in `.env` file SPOTIFY_REDIRECT_URI
- URL encoding issues (should be plain `vibzcheck://callback`)

**Fix:**
1. Copy-paste redirect URI from Dashboard: `vibzcheck://callback`
2. Paste into `.env` file: `SPOTIFY_REDIRECT_URI=vibzcheck://callback`
3. Paste into constants.dart fallback: `'vibzcheck://callback'`
4. All three must be identical (no trailing slashes, exact case match)

### Symptom: "Authorization successful but API calls fail (401)"
**Possible Causes:**
- Token expired (should be auto-refreshed by ensureAuthorized())
- Client Secret is invalid
- Scopes not authorized in Spotify Dashboard

**Fix:**
1. Check logs for "401 Unauthorized" responses
2. Verify .env Client Secret is correct (copy from Dashboard)
3. Verify scopes in spotify_service.dart match those authorized in Dashboard

### Symptom: "launchUrl fails" or "Cannot open Spotify auth URL"
**Possible Causes:**
- Authorization URL malformed
- Invalid Client ID
- Missing or invalid redirect URI in code

**Fix:**
1. Check logs for full authorization URL
2. Verify SPOTIFY_CLIENT_ID in .env is correct
3. Verify SPOTIFY_REDIRECT_URI in code is `vibzcheck://callback`

---

## 📚 Reference Documentation

- **Spotify Authorization Documentation**: https://developer.spotify.com/documentation/general/guides/authorization/
- **Deep-Linking in Flutter**: app_links package (used in this project)
- **Intent Filters for URL Schemes**: https://developer.android.com/guide/topics/manifest/intent-filter-element

---

## ✨ Current Status Summary

| Component | Status | Details |
|-----------|--------|---------|
| Android Intent-Filter | ✅ Verified | `vibzcheck://callback` configured in MainActivity |
| Constants File | ✅ Verified | spotifyRedirectUri = `vibzcheck://callback` |
| Spotify Service | ✅ Verified | Token validation & auto-refresh implemented |
| Deep-linking Library | ✅ Verified | app_links (not flutter_web_auth_2) |
| SearchScreen Prompt | ✅ Verified | Shows "Please authorize with Spotify" if not authenticated |
| Error Handling | ✅ Verified | 401 responses trigger re-authorization |
| **Spotify Dashboard** | ⚠️ **NOT VERIFIED** | **User must verify** redirect URI & scopes |

---

## 🎬 Next Steps

1. **Visit Spotify Developer Dashboard**: https://developer.spotify.com/dashboard
2. **Verify Redirect URI**: Ensure `vibzcheck://callback` is in your app's Redirect URIs list
3. **Verify Credentials**: Copy Client ID & Secret, add to `.env` if not already present
4. **Run App**: `flutter run -v` to start verbose logging
5. **Test OAuth Flow**: Follow testing checklist above
6. **Capture Logs**: If issues occur, share flutter run logs with verbose output

---

Generated: 2024
Updated after Spotify OAuth implementation and Firebase upgrade.
