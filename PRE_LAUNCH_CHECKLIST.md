# ✅ Pre-Launch Checklist

## Before Running the App on Device

### Step 1: Spotify Developer Setup ⭐ CRITICAL
- [ ] Visit https://developer.spotify.com/dashboard
- [ ] Log in to your Spotify Developer account
- [ ] Select your Vibzcheck app
- [ ] Go to **Settings** → **Redirect URIs**
- [ ] Verify `vibzcheck://callback` is in the list
- [ ] Copy **Client ID** and **Client Secret**

### Step 2: Environment Configuration
- [ ] Create `.env` file in project root (if not exists)
- [ ] Add the following lines:
  ```
  SPOTIFY_CLIENT_ID=<paste-your-client-id-here>
  SPOTIFY_CLIENT_SECRET=<paste-your-client-secret-here>
  SPOTIFY_REDIRECT_URI=vibzcheck://callback
  ```
- [ ] Save `.env` file
- [ ] ⚠️ **DO NOT COMMIT** `.env` to git (check `.gitignore`)

### Step 3: Clean Build
- [ ] Open terminal in project directory
- [ ] Run: `flutter clean`
- [ ] Wait for completion
- [ ] Run: `flutter pub get`
- [ ] Wait for completion
- [ ] Run: `flutter analyze`
- [ ] Verify output says: **"No issues found!"**

### Step 4: Prepare Device
- [ ] Connect Android device to computer (USB debugging enabled)
  - OR prepare iOS device with developer certificate
- [ ] Ensure device has Spotify app installed
- [ ] Ensure device can access Google Play / App Store

### Step 5: First Run
- [ ] Run: `flutter run -v`
- [ ] Wait for app to build and install
- [ ] App should open with SearchScreen
- [ ] **Expected**: "Please connect your Spotify account" dialog appears

---

## 🧪 Testing Checklist

### Test 1: Spotify Connection
- [ ] See "Connect Spotify" button/dialog
- [ ] Click "Connect Spotify"
- [ ] Spotify login page opens in browser
- [ ] Log in with your Spotify account
- [ ] See authorization prompt
- [ ] Click "Agree" to authorize app
- [ ] **Expected**: App resumes automatically
- [ ] **Expected**: See "✅ Spotify connected successfully!" message
- [ ] **Expected**: Search box is now enabled (not greyed out)
- [ ] **Expected**: Green checkmark appears in AppBar (top-right)

### Test 2: Song Search
- [ ] Type a song name (e.g., "Imagine") in search box
- [ ] Wait ~1 second for autocomplete
- [ ] **Expected**: Results appear from Spotify
- [ ] **Expected**: Album art shows for each song
- [ ] **Expected**: Artist name displays correctly
- [ ] Click any song
- [ ] **Expected**: Returns to previous screen with song selected

### Test 3: Real-Time Playlist Updates
- [ ] Add a song to a playlist
- [ ] Open the playlist details view
- [ ] **Expected**: Song count updates immediately (in real-time)
- [ ] **Expected**: No need to refresh or reload
- [ ] (Optional) Open same playlist on another device
- [ ] Add song from first device
- [ ] **Expected**: Second device sees update in real-time

### Test 4: Token Refresh (Advanced)
- [ ] Use app for 30+ minutes
- [ ] Try searching again
- [ ] **Expected**: Still works (token auto-refreshed)
- [ ] (Optional) Force kill app, wait 5 minutes, reopen
- [ ] Try searching
- [ ] **Expected**: Might show "Please authorize again" - click connect
- [ ] **Expected**: Works after re-auth

### Test 5: Error Handling
- [ ] Disconnect WiFi/disable mobile data
- [ ] Try searching
- [ ] **Expected**: See error message (not crash)
- [ ] Reconnect WiFi/mobile data
- [ ] Try searching again
- [ ] **Expected**: Works properly

---

## 🐛 Troubleshooting

### Issue: App crashes on startup
**Solution**:
- [ ] Check `.env` file exists in project root
- [ ] Check `.env` has valid Spotify credentials
- [ ] Check `.env` file is not committed to git (shouldn't cause crash though)
- [ ] Run `flutter clean && flutter pub get`
- [ ] Try `flutter run` again

### Issue: "Deep link not received" or app doesn't resume
**Solution**:
- [ ] Verify Spotify Dashboard Redirect URI is **exactly**: `vibzcheck://callback`
- [ ] Check AndroidManifest has intent-filter with `vibzcheck://callback`
- [ ] Ensure Spotify app is installed on device (not using browser)
- [ ] Try again from scratch: Close both apps, launch Vibzcheck, connect

### Issue: "Authorization successful but search fails (401)"
**Solution**:
- [ ] Verify `.env` Client Secret is correct (copy fresh from Dashboard)
- [ ] Check Spotify Dashboard - ensure all 5 scopes are authorized
- [ ] Try re-connecting: Click "Connect Spotify" again, complete flow
- [ ] Last resort: Delete app, `flutter clean`, reinstall

### Issue: Playlist shows "0 songs" despite adding songs
**Solution**:
- [ ] This should be fixed! Try:
  - [ ] Refresh the app (go back, come forward)
  - [ ] Check network connection
  - [ ] Verify songs were actually added in Firestore
  - [ ] If still broken, check logs: `flutter run -v | grep -i "snapshot"`

### Issue: Analyzer shows errors after modifications
**Solution**:
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] If errors persist, check the specific error message
- [ ] Do NOT modify core files (spotify_service.dart, firestore_service.dart) unless instructed

### Issue: App takes long time to build
**Solution**:
- [ ] First build after clean is always slow (5-10 minutes)
- [ ] Subsequent builds are faster (incremental)
- [ ] Don't interrupt the build
- [ ] Check your internet connection (downloading packages)

---

## 📚 Reference Documents

| Document | Purpose | When to Use |
|----------|---------|------------|
| **QUICK_START.md** | 5-minute overview | Getting started |
| **SESSION_SUMMARY.md** | What was fixed | Understanding changes |
| **SPOTIFY_OAUTH_VERIFICATION.md** | Detailed OAuth guide | If Spotify auth issues |
| **FINAL_STATUS_REPORT.md** | Technical deep-dive | Understanding implementation |
| **This file** | Execution checklist | Pre-launch verification |

---

## 🎯 Success Criteria

Your app is ready when:
- ✅ Analyzer shows: "No issues found!"
- ✅ Build completes without errors
- ✅ SearchScreen shows "Connect Spotify" on launch
- ✅ Spotify authentication flow completes
- ✅ Song search returns results
- ✅ Songs can be added to playlists
- ✅ Playlists update in real-time
- ✅ No crashes during normal usage

---

## 🚀 Launch Command

When ready, run:
```bash
flutter run -v
```

Then test using the checklist above.

---

## 📞 Questions?

Refer to the troubleshooting section above or check the detailed guides:
- **SPOTIFY_OAUTH_VERIFICATION.md** for auth issues
- **FINAL_STATUS_REPORT.md** for technical details
- **SESSION_SUMMARY.md** for what was changed

---

**Last Updated**: November 23, 2025  
**Analyzer Status**: ✅ No issues found!  
**Build Status**: ✅ Ready for testing
