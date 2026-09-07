import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth_repository.dart';
import '../access_repository.dart';

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
  Future<void> ensureProfile(MerchantIdentity identity) async {
    _checkSession(identity.uid);
    try {
      final ref = firestore.collection('merchants_new').doc(identity.uid);
      // Transactions require the server. Cached profile data never grants access.
      await firestore
          .runTransaction((transaction) async {
            final current = await transaction.get(ref);
            _checkSession(identity.uid);
            final fields = <String, dynamic>{
              'uid': identity.uid,
              'name': identity.name,
              'email': identity.email,
              'phoneNumber': identity.verifiedPhone,
              'updatedAt': FieldValue.serverTimestamp(),
              if (!current.exists) 'createdAt': FieldValue.serverTimestamp(),
            };
            transaction.set(ref, fields, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 20));
    } on FirebaseException catch (e) {
      throw AccessFailure(accessMessage(e.code));
    }
  }

  @override
  Stream<ShopAccessSnapshot> watchShops(String uid) {
    _checkSession(uid);
    return firestore
        .collection('merchant_shops')
        .where('merchantId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          _checkSession(uid);
          final shops =
              snapshot.docs
                  .map((doc) => MerchantShop.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
          return ShopAccessSnapshot(
            shops,
            serverConfirmed:
                !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites,
          );
        })
        .handleError((Object e) {
          throw AccessFailure(
            e is FirebaseException
                ? accessMessage(e.code)
                : 'Could not confirm shop access. Please reconnect.',
          );
        });
  }

  @override
  Stream<ApprovedAnchor?> watchApprovedAnchor({required String uid, required MerchantShop shop}) {
    _checkSession(uid);
    if (!shop.approved) throw const AccessFailure('This shop is waiting for Master approval.');
    return firestore.collection('merchant_anchors').doc(shop.anchorId)
      .snapshots(includeMetadataChanges: true).map((document) {
        _checkSession(uid);
        if (document.metadata.isFromCache || document.metadata.hasPendingWrites) return null;
        final data = document.data();
        if (data == null || data['merchantId'] != uid || data['shopId'] != shop.id || data['active'] != true) {
          throw const AccessFailure('This anchor is unavailable. Refresh or contact your Master.');
        }
        return ApprovedAnchor(id: document.id, shopId: shop.id, merchantId: uid);
      }).handleError((Object e) {
        throw AccessFailure(e is FirebaseException ? accessMessage(e.code) : 'This anchor is unavailable. Refresh or contact your Master.');
      });
  }

}

String accessMessage(String code) => switch (code) {
  'permission-denied' =>
    'Access is not approved or has been removed. Contact your Master, or check that the merchant database rules are deployed.',
  'unavailable' ||
  'deadline-exceeded' => 'Connect to the internet to confirm your shop access.',
  'not-found' =>
    'The merchant database is not available. Ask the administrator to complete Firebase setup.',
  _ => 'Could not load your merchant access. Please try again.',
};
