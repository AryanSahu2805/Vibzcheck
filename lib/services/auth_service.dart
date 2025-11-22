import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      
      // Get FCM token
      final fcmToken = await _fcm.getToken();
      
      // Create user document
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        fcmToken: fcmToken,
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());
      
      return userModel;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update FCM token and last active
      final fcmToken = await _fcm.getToken();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .update({
        'fcmToken': fcmToken,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Get user data
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();
      
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Clear FCM token
      if (currentUser != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(currentUser!.uid)
            .update({'fcmToken': null});
      }
      
      await _auth.signOut();
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }
  
  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Get user data error: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? profilePicture,
  }) async {
    try {
      if (currentUser == null) return;
      
      final Map<String, dynamic> updates = {};
      
      if (displayName != null) {
        updates['displayName'] = displayName;
        await currentUser!.updateDisplayName(displayName);
      }
      
      if (profilePicture != null) {
        updates['profilePicture'] = profilePicture;
      }
      
      updates['lastActive'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update(updates);
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }
  
  // Update FCM token
  Future<void> updateFCMToken() async {
    try {
      if (currentUser == null) return;
      
      final fcmToken = await _fcm.getToken();
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
        'fcmToken': fcmToken,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Update FCM token error: $e');
    }
  }
  
  // Link Spotify account
  Future<void> linkSpotifyAccount({
    required String spotifyId,
    required Map<String, dynamic> spotifyData,
  }) async {
    try {
      if (currentUser == null) return;
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
        'spotifyId': spotifyId,
        'spotifyData': spotifyData,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Link Spotify error: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('❌ Reset password error: $e');
      rethrow;
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) return;
      
      // Delete user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .delete();
      
      // Delete auth account
      await currentUser!.delete();
    } catch (e) {
      print('❌ Delete account error: $e');
      rethrow;
    }
  }
  
  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ Email exists check error: $e');
      return false;
    }
  }
}