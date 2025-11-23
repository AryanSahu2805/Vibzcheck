import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
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
      
      // Get FCM token (REQUIRED for notifications)
      String? fcmToken;
      try {
        fcmToken = await _fcm.getToken();
        if (fcmToken == null) {
          Logger.info('⚠️ FCM token is null');
        }
      } catch (e) {
        Logger.info('⚠️ Could not get FCM token: $e');
        // Continue anyway - notifications won't work but app can function
      }
      
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
      Logger.info('❌ Sign up error: $e');
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
      
  Logger.success('Firebase Auth sign in successful for: ${credential.user?.email}');
      
      // Update FCM token and last active (REQUIRED for notifications)
      try {
        final fcmToken = await _fcm.getToken();
          if (fcmToken != null) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(credential.user!.uid)
              .update({
            'fcmToken': fcmToken,
            'lastActive': FieldValue.serverTimestamp(),
          });
          Logger.success('FCM token updated');
        }
      } catch (e) {
  Logger.warning('Could not update FCM token: $e');
        // Continue anyway - notifications won't work but app can function
      }
      
      // Get user data
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
  Logger.warning('User document not found in Firestore for UID: ${credential.user!.uid}');
  Logger.info('Creating user document from Firebase Auth data...');
        
        // Create user document if it doesn't exist
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'User',
          createdAt: credential.user!.metadata.creationTime ?? DateTime.now(),
          lastActive: DateTime.now(),
          fcmToken: await _fcm.getToken(),
        );
        
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        
  Logger.success('User document created in Firestore');
        return userModel;
      }
      
      Logger.success('User document found in Firestore');
      try {
        return UserModel.fromFirestore(userDoc);
      } catch (e, st) {
        Logger.error('Error parsing user from Firestore', e, st);
        // If parsing fails, create a basic user model from Firebase Auth
        Logger.info('Creating fallback user model from Firebase Auth data');
        final fallbackUser = UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'User',
          createdAt: credential.user!.metadata.creationTime ?? DateTime.now(),
          lastActive: DateTime.now(),
        );
        return fallbackUser;
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase Auth Exception: ${e.code} - ${e.message}');
      String friendlyMessage = _getFriendlyErrorMessage(e.code);
      Logger.info('Sign in error: $friendlyMessage');
      throw Exception(friendlyMessage);
    } catch (e, st) {
      Logger.error('Sign in error', e, st);
      Logger.info('Sign in error: $e');
      rethrow;
    }
  }
  
  // Convert Firebase error codes to user-friendly messages
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email not registered. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'Login failed: $code. Please try again.';
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
      Logger.info('❌ Sign out error: $e');
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
      
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromFirestore(doc);
        } catch (e, st) {
          Logger.error('Error parsing user document from Firestore', e, st);
          // Return a basic user model created from Firebase Auth
          if (currentUser != null) {
            return UserModel(
              uid: uid,
              email: currentUser!.email ?? '',
              displayName: currentUser!.displayName ?? 'User',
              createdAt: currentUser!.metadata.creationTime ?? DateTime.now(),
              lastActive: DateTime.now(),
            );
          }
        }
      }
      
      // If user document doesn't exist, create a basic one
      if (currentUser != null) {
        final basicUser = UserModel(
          uid: uid,
          email: currentUser!.email ?? '',
          displayName: currentUser!.displayName ?? 'User',
          createdAt: currentUser!.metadata.creationTime ?? DateTime.now(),
          lastActive: DateTime.now(),
        );
        
        try {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .set(basicUser.toFirestore());
          return basicUser;
        } catch (e) {
          Logger.info('⚠️ Could not create user document: $e');
          return basicUser; // Return anyway
        }
      }
      
      return null;
    } catch (e, st) {
      Logger.error('Get user data error', e, st);
      // Return a basic user model if we have current user
      if (currentUser != null) {
        return UserModel(
          uid: uid,
          email: currentUser!.email ?? '',
          displayName: currentUser!.displayName ?? 'User',
          createdAt: currentUser!.metadata.creationTime ?? DateTime.now(),
          lastActive: DateTime.now(),
        );
      }
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
      Logger.info('❌ Update profile error: $e');
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
      Logger.info('❌ Update FCM token error: $e');
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
      Logger.info('❌ Link Spotify error: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      Logger.info('❌ Reset password error: $e');
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
      Logger.info('❌ Delete account error: $e');
      rethrow;
    }
  }
  
  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      Logger.info('❌ Email exists check error: $e');
      return false;
    }
  }
  
  // Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No user logged in');
      }
      
      // Reauthenticate with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email ?? '',
        password: currentPassword,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
  Logger.success('Reauthentication successful');
      
      // Update password
      await currentUser!.updatePassword(newPassword);
  Logger.success('Password updated successfully');
      
      Logger.info('✅ Password updated');
    } on FirebaseAuthException catch (e) {
      Logger.error('Password update FirebaseAuthException: ${e.code} - ${e.message}');
      String friendlyMessage = _getFriendlyPasswordErrorMessage(e.code);
      throw Exception(friendlyMessage);
    } catch (e) {
      Logger.error('Password update error', e);
      Logger.info('Password update error: $e');
      rethrow;
    }
  }
  
  // Convert Firebase password error codes to user-friendly messages
  String _getFriendlyPasswordErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'User not found. Please log in again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Failed to update password: $code. Please try again.';
    }
  }
}
