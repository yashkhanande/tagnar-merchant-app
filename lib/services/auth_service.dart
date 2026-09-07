import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(serverClientId: null);

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google sign in error: $e");
      return null;
    }
  }

  Future<void> createUser() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final ref = _firestore.collection("merchants_new").doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        "uid": user.uid,
        "email": user.email,
        "name": user.displayName,
        "photoUrl": user.photoURL,
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        "lastLogin": FieldValue.serverTimestamp(),
        "name": user.displayName,
        "photoUrl": user.photoURL,
        "email": user.email,
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No logged-in user found.");
    }

    final String uid = user.uid;

    // IMPORTANT:
    // Re-authenticate BEFORE deleting Firestore data.
    // Firebase Auth can require a recent login for account deletion.
    await _reauthenticateGoogleUser(user);

    // Delete user's Firestore profile/data.
    await _firestore.collection("merchants_new").doc(uid).delete();

    // If you have other user-specific Firestore collections,
    // delete those here BEFORE deleting Firebase Auth.
    //
    // Example:
    // await _firestore.collection("user_progress").doc(uid).delete();

    // Delete Firebase Authentication account.
    await user.delete();

    // Clear Google Sign-In session.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase account is already deleted.
      // Don't fail the whole deletion because local Google
      // session cleanup failed.
    }
  }

  Future<void> _reauthenticateGoogleUser(User user) async {
    try {
      await _googleSignIn.initialize(serverClientId: null);

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception("Google verification failed: $e");
    }
  }
}
