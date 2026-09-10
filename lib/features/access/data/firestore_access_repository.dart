import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth_repository.dart';
import '../access_repository.dart';
import '../../../models/onboarding_details.dart';

class FirestoreMerchantAccessRepository implements MerchantAccessRepository {
  FirestoreMerchantAccessRepository({
    required this.firestore,
    required this.functions,
    required this.auth,
  });
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
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
      await functions
          .httpsCallable('ensureMerchantProfile')
          .call<void>()
          .timeout(const Duration(seconds: 20));
      final snapshot = await ref.get(const GetOptions(source: Source.server));
      final data = snapshot.data();
      if (data == null) {
        throw const AccessFailure('Could not create your merchant profile.');
      }
      return MerchantProfile(
        onboardingCompleted: data['onboardingCompleted'] == true,
        details: OnboardingDetails.fromMap(data),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AccessFailure(_functionMessage(e));
    } on FirebaseException catch (e) {
      throw AccessFailure(accessMessage(e.code));
    }
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingDetails details) async {
    _checkSession(uid);
    try {
      await functions
          .httpsCallable('updateMerchantProfile')
          .call<void>(details.toMap())
          .timeout(const Duration(seconds: 20));
    } on FirebaseFunctionsException catch (e) {
      throw AccessFailure(_functionMessage(e));
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

String _functionMessage(FirebaseFunctionsException error) =>
    switch (error.code) {
      'unauthenticated' => 'Sign in and verify your phone to continue.',
      'permission-denied' => error.message ?? 'Merchant access is unavailable.',
      'invalid-argument' => error.message ?? 'Check your business details.',
      'unavailable' || 'deadline-exceeded' =>
        'The secure merchant service is unavailable. Please try again.',
      _ => error.message ?? 'Could not save your merchant profile.',
    };

String accessMessage(String code) => switch (code) {
  'permission-denied' =>
    'Access is not approved or has been removed. Contact your Master, or check that the merchant database rules are deployed.',
  'unavailable' ||
  'deadline-exceeded' => 'Connect to the internet to confirm anchor access.',
  'not-found' =>
    'The merchant database is not available. Ask the administrator to complete Firebase setup.',
  _ => 'Could not load your merchant access. Please try again.',
};
