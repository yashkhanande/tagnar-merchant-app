import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    app: _auth.app,
    region: 'asia-south1',
  );

  Future<void> createUser() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _functions.httpsCallable('ensureMerchantProfile').call<void>();
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

    await _functions.httpsCallable('deleteMerchantAccount').call<void>();
  }
}
