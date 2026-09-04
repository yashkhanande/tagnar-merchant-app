import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/onboarding_details.dart';

class OnboardingService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  OnboardingService({
    required this.firestore,
    required this.auth,
  });

  DocumentReference<Map<String, dynamic>> _document(String uid) {
    if (auth.currentUser?.uid != uid) {
      throw StateError('The authenticated account has changed.');
    }

    // Match this collection to your existing MerchantService.
    return firestore.collection('merchants_new').doc(uid);
  }

  Future<OnboardingDetails> load(String uid) async {
    final snapshot = await _document(uid).get();
    final data = snapshot.data();

    return data == null
        ? const OnboardingDetails()
        : OnboardingDetails.fromMap(data);
  }

  Future<void> save(String uid, OnboardingDetails details) async {
    await _document(uid).set(
      details.toMap(),
      SetOptions(merge: true),
    );
  }
}