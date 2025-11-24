# Vibzcheck - Complete Testing Guide

This guide provides step-by-step instructions to test all functionality in the Vibzcheck app.

---

## 📱 Prerequisites

1. **App Setup**
   - Ensure the app is built and installed on your device/emulator
   - Firebase project is configured
   - Spotify Developer credentials are set in `.env` file
   - Internet connection is available

2. **Test Accounts**
   - Create at least 2 test accounts (for collaboration testing)
   - Have Spotify accounts ready (or use test mode)

---

## 🧪 Testing Checklist

### ✅ Week 1: User Authentication & Profiles

#### Test 1.1: User Registration
**Steps:**
1. Launch the app
2. You should see the **Onboarding Screen** (if first launch)
3. Swipe through onboarding pages or tap "Skip"
4. Tap **"Sign Up"** button
5. Fill in the form:
   - **Display Name**: Enter your name (e.g., "John Doe")
   - **Email**: Enter a valid email (e.g., "test@example.com")
   - **Password**: Enter a password (min 6 characters)
6. Tap **"Sign Up"** button
7. **Expected Result**: 
   - App navigates to Home Screen
   - Profile is created successfully
   - You are logged in

**Verify:**
- ✅ No error messages appear
- ✅ Home screen shows "My Playlists"
- ✅ Profile icon appears in top right

---

#### Test 1.2: User Login
**Steps:**
1. If already logged in, tap **Profile Icon** → **Sign Out**
2. On Auth Screen, tap **"Sign In"**
3. Enter credentials:
   - **Email**: Use the email from Test 1.1
   - **Password**: Use the password from Test 1.1
4. Tap **"Sign In"** button
5. **Expected Result**: 
   - App navigates to Home Screen
   - You are logged in successfully

**Verify:**
- ✅ Login successful
- ✅ Home screen displays correctly
- ✅ User data loads properly

---

#### Test 1.3: Profile Viewing
**Steps:**
1. From Home Screen, tap **Profile Icon** (top right)
2. **Expected Result**: Profile screen displays with:
   - Your profile picture (or placeholder)
   - Your display name
   - Your email
   - User statistics
   - Your playlists list

**Verify:**
- ✅ Display name shows correctly (not "User")
- ✅ Profile picture displays (if uploaded)
- ✅ Email is visible
- ✅ Playlists list is shown

---

#### Test 1.4: Profile Editing
**Steps:**
1. From Profile Screen, tap **Settings Icon** (gear icon)
2. In Settings Screen:
   - **Update Display Name**: 
     - Enter a new name in "Display Name" field
     - Tap **"Update Display Name"** button
     - **Expected**: Success message appears
   - **Update Profile Picture**:
     - Tap on profile picture
     - Select image from gallery
     - **Expected**: Image uploads and updates
3. Go back to Profile Screen
4. **Expected Result**: 
   - Updated display name is shown
   - Updated profile picture is displayed

**Verify:**
- ✅ Display name updates correctly
- ✅ Profile picture updates correctly
- ✅ Changes persist after app restart

---

#### Test 1.5: Password Change
**Steps:**
1. From Settings Screen, scroll to **"Security"** section
2. Enter:
   - **Current Password**: Your current password
   - **New Password**: A new password
   - **Confirm Password**: Same new password
3. Tap **"Change Password"** button
4. **Expected Result**: 
   - Success message appears
   - Password is updated

**Verify:**
- ✅ Password change successful
- ✅ Can login with new password
- ✅ Cannot login with old password

---

### ✅ Week 2: Collaborative Playlist System

#### Test 2.1: Create Playlist
**Steps:**
1. From Home Screen, tap **"+ Create Playlist"** button
2. Fill in the form:
   - **Playlist Name**: Enter a name (e.g., "My Test Playlist")
   - **Description**: Enter optional description
   - **Cover Image**: Tap to add cover image (optional)
   - **Public/Private**: Toggle as desired
3. Tap **"Create"** button
4. **Expected Result**: 
   - Playlist is created
   - App navigates to the new playlist view
   - Share code is displayed (e.g., "Code: ABC123")

**Verify:**
- ✅ Playlist appears in "My Playlists" list
- ✅ Playlist view shows correct information
- ✅ Share code is visible
- ✅ Creator name shows correctly (not "User")

---

#### Test 2.2: Join Playlist by Share Code
**Steps:**
1. **On Device 1**: Create a playlist (from Test 2.1)
2. Note the **Share Code** displayed (e.g., "ABC123")
3. **On Device 2** (or different account):
   - Open the app
   - From Home Screen, tap **"+ Join Playlist"** button
   - Enter the share code (e.g., "ABC123")
   - Tap **"Join"** button
4. **Expected Result**: 
   - Playlist is joined successfully
   - App navigates to the playlist view
   - User appears in participants list

**Verify:**
- ✅ Playlist appears in joined user's "My Playlists"
- ✅ Both users see each other in participants list
- ✅ Participant names show correctly (not "User")

---

#### Test 2.3: Real-time Playlist Updates
**Steps:**
1. **On Device 1**: Open a playlist
2. **On Device 2**: Open the same playlist
3. **On Device 1**: Add a song (see Test 2.4)
4. **Expected Result on Device 2**: 
   - Song count updates automatically
   - New song appears in the list
   - No manual refresh needed

**Verify:**
- ✅ Changes sync in real-time
- ✅ Song count updates automatically
- ✅ New songs appear instantly

---

### ✅ Week 2: Spotify API Integration

#### Test 2.4: Connect Spotify Account
**Steps:**
1. From Home Screen or Profile Screen, look for **"Connect Spotify"** option
2. Tap **"Connect Spotify"** button
3. **Expected Result**: 
   - Browser/WebView opens
   - Spotify login page appears
4. Enter Spotify credentials and authorize
5. **Expected Result**: 
   - App returns from browser
   - Spotify connection successful
   - Authorization persists

**Verify:**
- ✅ Spotify authorization successful
- ✅ Token persists after app restart
- ✅ Can search songs without re-authorizing

---

#### Test 2.5: Search Songs
**Steps:**
1. Open a playlist (create one if needed)
2. Tap **"+ Add Songs"** button
3. In Search Screen, enter a song name (e.g., "Shape of You")
4. Wait for search results (debounced, ~800ms)
5. **Expected Result**: 
   - Search results appear
   - Each result shows:
     - Album artwork
     - Song name
     - Artist name
     - Album name
     - Duration
     - "+" button to add

**Verify:**
- ✅ Search returns relevant results
- ✅ Results display correctly
- ✅ No "authorization expired" errors
- ✅ Can search multiple times

---

#### Test 2.6: Add Song to Playlist
**Steps:**
1. From Search Screen (Test 2.5), tap **"+"** button on a song
2. **Expected Result**: 
   - Song is added to playlist
   - Success message appears (e.g., "Added 'Song Name' to playlist")
   - App returns to playlist view
3. In Playlist View, verify:
   - Song appears in the list
   - Song count increases
   - "Added by [Your Name]" shows correctly (not "User")

**Verify:**
- ✅ Song appears in playlist
- ✅ Song count updates
- ✅ "Added by" shows correct name
- ✅ Song metadata is complete

---

### ✅ Week 2: Democratic Voting System

#### Test 2.7: Vote on Songs
**Steps:**
1. Open a playlist with songs
2. On any song, you'll see:
   - **Up arrow** (green) - Upvote
   - **Vote score** (number in middle)
   - **Down arrow** (red) - Downvote
3. Tap **Up arrow** on a song
4. **Expected Result**: 
   - Vote score increases
   - Your vote is registered
   - Song may move up in the list (if sorted by votes)

**Verify:**
- ✅ Vote score updates immediately
- ✅ Can change vote (upvote to downvote)
- ✅ Songs are sorted by vote score (highest first)

---

#### Test 2.8: Real-time Vote Synchronization
**Steps:**
1. **On Device 1**: Open a playlist
2. **On Device 2**: Open the same playlist
3. **On Device 1**: Upvote a song
4. **Expected Result on Device 2**: 
   - Vote score updates automatically
   - No manual refresh needed
   - Changes appear instantly

**Verify:**
- ✅ Votes sync in real-time
- ✅ Vote scores update on all devices
- ✅ Song order updates if needed

---

### ✅ Week 3: Playlist Chat Rooms

#### Test 3.1: Send Chat Message
**Steps:**
1. Open a playlist
2. Tap **"Chat"** button
3. In Chat Screen, type a message in the text field
4. Tap **Send** button (or press Enter)
5. **Expected Result**: 
   - Message appears in chat
   - Your name and profile picture are shown
   - Timestamp is displayed
   - Message appears in a bubble

**Verify:**
- ✅ Message sends successfully
- ✅ Message displays correctly
- ✅ Sender name shows correctly (not "User")
- ✅ Timestamp is accurate

---

#### Test 3.2: Real-time Chat Synchronization
**Steps:**
1. **On Device 1**: Open a playlist chat
2. **On Device 2**: Open the same playlist chat
3. **On Device 1**: Send a message
4. **Expected Result on Device 2**: 
   - Message appears automatically
   - No manual refresh needed
   - Message appears in real-time

**Verify:**
- ✅ Messages sync in real-time
- ✅ All participants see messages instantly
- ✅ Message history loads correctly

---

#### Test 3.3: Chat Message History
**Steps:**
1. Send several messages in a chat
2. Close the chat screen
3. Reopen the chat screen
4. **Expected Result**: 
   - All previous messages are displayed
   - Messages are in chronological order
   - Timestamps are shown

**Verify:**
- ✅ Message history loads
- ✅ Messages are ordered correctly
- ✅ All participants' messages are visible

---

### ✅ Week 3: Music Genre & Mood Tagging

#### Test 3.4: Verify Mood Tags
**Steps:**
1. Add a song to a playlist (from Test 2.6)
2. The song should automatically receive mood tags based on audio features
3. Check the song data (you may need to inspect Firestore or add UI to display tags)
4. **Expected Result**: 
   - Song has mood tags assigned (e.g., "Chill", "Party", "Focus")
   - Tags are based on audio features from Spotify

**Verify:**
- ✅ Mood tags are assigned automatically
- ✅ Tags match the song's characteristics
- ✅ Tags are stored in Firestore

---

### ✅ Must-Solve Challenges

#### Test 4.1: Real-time Vote Synchronization
**Steps:**
1. **On Device 1**: Open a playlist
2. **On Device 2**: Open the same playlist (same or different account)
3. **On Device 1**: Vote on a song
4. **Expected Result on Device 2**: 
   - Vote score updates within 1-2 seconds
   - No page refresh needed
   - Changes are visible immediately

**Verify:**
- ✅ Real-time synchronization works
- ✅ No delays or lag
- ✅ All users see updates instantly

---

#### Test 4.2: Spotify API Integration with Firebase
**Steps:**
1. Search and add a song (from Test 2.5 and 2.6)
2. **Expected Result**: 
   - Song data from Spotify is stored in Firestore
   - Song includes:
     - Spotify track ID
     - Track name, artist, album
     - Preview URL
     - Audio features
     - Mood tags
3. Check Firestore database to verify data structure

**Verify:**
- ✅ Spotify data is stored in Firestore
- ✅ All metadata is preserved
- ✅ Track IDs link correctly

---

#### Test 4.3: Complex Playlist State Management
**Steps:**
1. Create a playlist
2. Add multiple songs
3. Have multiple users vote on different songs
4. Add/remove participants
5. Send chat messages
6. **Expected Result**: 
   - All state updates correctly
   - No data loss or corruption
   - UI reflects all changes accurately

**Verify:**
- ✅ State management works correctly
- ✅ No conflicts or errors
- ✅ All features work together

---

#### Test 4.4: Caching and Offline Playback
**Steps:**
1. Add a song with preview URL to a playlist
2. Tap on the song to play preview
3. **Expected Result**: 
   - Preview plays (30 seconds max)
   - Preview is cached locally
4. Turn off internet/WiFi
5. Try to play the same preview again
6. **Expected Result**: 
   - Preview plays from cache
   - No internet required
   - Works offline

**Verify:**
- ✅ Previews cache correctly
- ✅ Offline playback works
- ✅ 30-second limit is enforced
- ✅ Cache persists after app restart

---

#### Test 4.5: Delete Song
**Steps:**
1. Open a playlist with songs
2. On a song you added (or as playlist creator), you should see a **Delete** button (trash icon)
3. Tap the **Delete** button
4. Confirm deletion in the dialog
5. **Expected Result**: 
   - Song is removed from playlist
   - Song count decreases
   - Success message appears

**Verify:**
- ✅ Song is deleted successfully
- ✅ Song count updates
- ✅ Only creator or song adder can delete
- ✅ Other users cannot delete songs they didn't add

---

## 🔍 Additional Verification Tests

### Test 5.1: Error Handling
**Steps:**
1. Try to login with wrong password
2. Try to join playlist with invalid code
3. Try to search without Spotify authorization
4. **Expected Result**: 
   - Appropriate error messages appear
   - App doesn't crash
   - User can recover from errors

**Verify:**
- ✅ Error messages are user-friendly
- ✅ No crashes occur
- ✅ App handles errors gracefully

---

### Test 5.2: User Name Display
**Steps:**
1. Check all places where user names appear:
   - Playlist cards ("by [Name]")
   - Participants list
   - Chat messages
   - "Added by [Name]" on songs
   - Profile screen
2. **Expected Result**: 
   - All show actual user names (not "User")
   - Names are consistent across the app

**Verify:**
- ✅ No "User" placeholders appear
- ✅ Names display correctly everywhere
- ✅ Email prefix used as fallback if needed

---

### Test 5.3: App Restart Persistence
**Steps:**
1. Login to the app
2. Create a playlist
3. Add some songs
4. Close the app completely
5. Reopen the app
6. **Expected Result**: 
   - You remain logged in
   - Playlists are still there
   - Songs are still in playlists
   - Spotify authorization persists

**Verify:**
- ✅ Session persists
- ✅ Data is saved
- ✅ No data loss

---

## 📊 Testing Summary Checklist

Use this checklist to track your testing progress:

### Week 1: User Authentication & Profiles
- [ ] User Registration
- [ ] User Login
- [ ] Profile Viewing
- [ ] Profile Editing
- [ ] Password Change

### Week 2: Collaborative Playlist System
- [ ] Create Playlist
- [ ] Join Playlist by Share Code
- [ ] Real-time Playlist Updates

### Week 2: Spotify API Integration
- [ ] Connect Spotify Account
- [ ] Search Songs
- [ ] Add Song to Playlist

### Week 2: Democratic Voting System
- [ ] Vote on Songs
- [ ] Real-time Vote Synchronization

### Week 3: Playlist Chat Rooms
- [ ] Send Chat Message
- [ ] Real-time Chat Synchronization
- [ ] Chat Message History

### Week 3: Music Genre & Mood Tagging
- [ ] Verify Mood Tags

### Must-Solve Challenges
- [ ] Real-time Vote Synchronization
- [ ] Spotify API Integration with Firebase
- [ ] Complex Playlist State Management
- [ ] Caching and Offline Playback
- [ ] Delete Song

### Additional Tests
- [ ] Error Handling
- [ ] User Name Display
- [ ] App Restart Persistence

---

## 🐛 Common Issues & Solutions

### Issue: "Spotify authorization expired"
**Solution**: 
- Tap "Connect Spotify" button
- Re-authorize with Spotify
- Token will persist after re-authorization

### Issue: Songs not appearing
**Solution**:
- Check internet connection
- Verify Spotify authorization
- Try refreshing the playlist

### Issue: Votes not syncing
**Solution**:
- Check internet connection
- Verify Firestore rules are deployed
- Ensure real-time listeners are active

### Issue: Preview not playing
**Solution**:
- Check if song has preview URL
- Verify internet connection (for first play)
- Check audio permissions

---

## 📝 Notes

- **Real-time Features**: All real-time features require active internet connection
- **Offline Playback**: Only cached previews work offline
- **Spotify Authorization**: Required for searching and adding songs
- **Multiple Users**: Some features require testing with multiple accounts/devices

---

**Last Updated**: $(date)
**App Version**: 1.0.0

