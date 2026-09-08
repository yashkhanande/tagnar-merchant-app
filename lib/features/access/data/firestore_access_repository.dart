import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth_repository.dart';
import '../access_repository.dart';
import '../../../models/onboarding_details.dart';

class FirestoreMerchantAccessRepository implements MerchantAccessRepository {
  FirestoreMerchantAccessRepository({
    required this.firestore,
    required this.auth,
  });
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  void _checkSession(String uid) {
    if (auth.currentUser?.uid != uid || auth.currentUser?.phoneNumber == null) {
      throw const AccessFailure('Sign in and verify your phone to continue.');
    }
  }

  @override
  Future<MerchantProfile> ensureProfile(MerchantIdentity identity) async {
    if (auth.currentUser?.uid != identity.uid) {
      throw const AccessFailure('Sign in to continue.');
    }
    try {
      final ref = firestore.collection('merchants_new').doc(identity.uid);
      final data = await firestore
          .runTransaction((transaction) async {
            final current = await transaction.get(ref);
            if (auth.currentUser?.uid != identity.uid) {
              throw const AccessFailure('Your sign-in session changed.');
            }
            final fields = <String, dynamic>{
              'uid': identity.uid,
              'name': identity.name,
              'email': identity.email,
              'photoUrl': identity.photoUrl,
              if (identity.verifiedPhone != null)
                'phoneNumber': identity.verifiedPhone,
              'lastLogin': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              if (!current.exists) 'createdAt': FieldValue.serverTimestamp(),
            };
            transaction.set(ref, fields, SetOptions(merge: true));
            return {...?current.data(), ...fields};
          })
          .timeout(const Duration(seconds: 20));
      return MerchantProfile(
        onboardingCompleted: data['onboardingCompleted'] == true,
        details: OnboardingDetails.fromMap(data),
      );
    } on FirebaseException catch (e) {
      throw AccessFailure(accessMessage(e.code));
    }
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingDetails details) async {
    _checkSession(uid);
    try {
      await firestore
          .collection('merchants_new')
          .doc(uid)
          .set({
            ...details.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 20));
    } on FirebaseException catch (e) {
      throw AccessFailure(accessMessage(e.code));
    }
  }

  @override
  Stream<AnchorAccessSnapshot> watchAnchors(String uid) {
    _checkSession(uid);
    return firestore
        .collection('anchor')
        .where('merchantId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          _checkSession(uid);
          final anchors =
              snapshot.docs
                  .map((doc) => MerchantAnchor.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
          return AnchorAccessSnapshot(
            anchors,
            serverConfirmed:
                !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites,
          );
        })
        .handleError((Object e) {
          throw AccessFailure(
            e is FirebaseException
                ? accessMessage(e.code)
                : 'Could not confirm anchor access. Please reconnect.',
          );
        });
  }
}

String accessMessage(String code) => switch (code) {
  'permission-denied' =>
    'Access is not approved or has been removed. Contact your Master, or check that the merchant database rules are deployed.',
  'unavailable' ||
  'deadline-exceeded' => 'Connect to the internet to confirm anchor access.',
  'not-found' =>
    'The merchant database is not available. Ask the administrator to complete Firebase setup.',
  _ => 'Could not load your merchant access. Please try again.',
};
