import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final ref = _firestore.collection("merchants_new").doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        "uid": user.uid,
        "email": user.email ?? '',
        "name": user.displayName ?? 'Merchant',
        "photoUrl": user.photoURL ?? '',
        "phoneNumber": user.phoneNumber ?? '',
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        "lastLogin": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "name": user.displayName ?? 'Merchant',
        "photoUrl": user.photoURL ?? '',
        "email": user.email ?? '',
        "phoneNumber": user.phoneNumber ?? '',
      });
    }
  }

  Future<void> signOut() async {
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

    // Delete user's Firestore profile/data.
    await _firestore.collection("merchants_new").doc(uid).delete();

    // If you have other user-specific Firestore collections,
    // delete those here BEFORE deleting Firebase Auth.
    //
    // Example:
    // await _firestore.collection("user_progress").doc(uid).delete();

    // Delete Firebase Authentication account.
    await user.delete();
  }
}
