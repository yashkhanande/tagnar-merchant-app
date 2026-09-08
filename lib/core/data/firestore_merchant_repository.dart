import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../merchant_repository.dart';
import '../models.dart';

/// Firestore-backed merchant data scoped to one merchant-owned anchor.
class FirestoreMerchantRepository implements MerchantRepository {
  FirestoreMerchantRepository({
    required this.firestore,
    required this.auth,
    required this.merchantId,
    required this.merchantName,
    required this.anchorId,
    required this.anchorName,
    required this.anchorLocation,
    required this.phone,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final String merchantId, merchantName, anchorId, anchorName, anchorLocation;
  final String phone;

  void _checkSession() {
    if (auth.currentUser?.uid != merchantId ||
        auth.currentUser?.phoneNumber == null) {
      throw const MerchantException('Your session expired. Sign in again.');
    }
  }

  Query<Map<String, dynamic>> _forAnchor(String collection) => firestore
      .collection(collection)
      .where('merchantId', isEqualTo: merchantId)
      .where('anchorId', isEqualTo: anchorId);

  @override
  Future<MerchantSnapshot> load({
    DemoScenario scenario = DemoScenario.normal,
  }) async {
    _checkSession();
    try {
      final results = await Future.wait([
        _forAnchor(
          'merchant_requests',
        ).get(const GetOptions(source: Source.server)),
        _forAnchor(
          'merchant_offers',
        ).get(const GetOptions(source: Source.server)),
        _forAnchor(
          'merchant_payments',
        ).get(const GetOptions(source: Source.server)),
        _forAnchor(
          'merchant_interactions',
        ).get(const GetOptions(source: Source.server)),
        _forAnchor(
          'merchant_conversations',
        ).get(const GetOptions(source: Source.server)),
      ]).timeout(const Duration(seconds: 25));
      _checkSession();

      final requests = results[0].docs.map(_request).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final offers = results[1].docs.map(_offer).toList()
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      final payments = results[2].docs.map(_payment).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final interactions = results[3].docs.map(_interaction).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final conversations = <Conversation>[];
      for (final doc in results[4].docs) {
        final messageDocs = await doc.reference
            .collection('messages')
            .orderBy('sentAt')
            .limit(500)
            .get(const GetOptions(source: Source.server));
        conversations.add(_conversation(doc, messageDocs.docs));
      }
      conversations.sort((a, b) {
        final ad = a.messages.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : a.messages.last.sentAt;
        final bd = b.messages.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : b.messages.last.sentAt;
        return bd.compareTo(ad);
      });

      return MerchantSnapshot(
        profile: AnchorProfile(
          merchantId: merchantId,
          name: merchantName,
          anchorName: anchorName,
          anchorId: anchorId,
          location: anchorLocation,
          phone: phone,
          phoneConfirmed: true,
        ),
        requests: requests,
        offers: offers,
        payments: payments,
        interactions: interactions,
        conversations: conversations,
      );
    } on FirebaseException catch (e) {
      throw MerchantException(_firebaseMessage(e.code));
    } on MerchantException {
      rethrow;
    } on FormatException catch (e) {
      throw MerchantException('Some anchor data is invalid: ${e.message}');
    } catch (_) {
      throw const MerchantException(
        'Could not load anchor data. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> respondToOffer(String offerId, OfferDecision decision) async {
    _checkSession();
    final ref = firestore.collection('merchant_offers').doc(offerId);
    try {
      await firestore
          .runTransaction((transaction) async {
            final snapshot = await transaction.get(ref);
            final data = snapshot.data();
            if (data == null ||
                data['merchantId'] != merchantId ||
                data['anchorId'] != anchorId) {
              throw const MerchantException('Offer not found.');
            }
            if (data['decision'] != null) {
              throw const MerchantException(
                'This offer already has a saved response.',
              );
            }
            final expiresAt = _date(data['expiresAt'], 'expiresAt');
            if (!expiresAt.isAfter(DateTime.now())) {
              throw const MerchantException('This offer has expired.');
            }
            transaction.update(ref, {
              'decision': decision.name,
              'decidedAt': FieldValue.serverTimestamp(),
              'decidedBy': merchantId,
            });
          })
          .timeout(const Duration(seconds: 20));
    } on FirebaseException catch (e) {
      throw MerchantException(_firebaseMessage(e.code));
    }
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    _checkSession();
    final value = text.trim();
    if (value.isEmpty || value.length > 1000) {
      throw const MerchantException('Enter a message of 1–1,000 characters.');
    }
    final conversation = firestore
        .collection('merchant_conversations')
        .doc(conversationId);
    try {
      final current = await conversation.get(
        const GetOptions(source: Source.server),
      );
      final data = current.data();
      if (data == null ||
          data['merchantId'] != merchantId ||
          data['anchorId'] != anchorId) {
        throw const MerchantException('Conversation not found.');
      }
      await conversation.collection('messages').add({
        'text': value,
        'sentAt': FieldValue.serverTimestamp(),
        'senderId': merchantId,
        'fromMerchant': true,
      });
    } on FirebaseException catch (e) {
      throw MerchantException(_firebaseMessage(e.code));
    }
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    _checkSession();
    try {
      await firestore
          .collection('merchant_conversations')
          .doc(conversationId)
          .update({'unread': 0, 'readAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw MerchantException(_firebaseMessage(e.code));
    }
  }

  @override
  Future<void> requestPhoneCode(String phone) async =>
      throw const MerchantException(
        'Your phone is already verified through Firebase Authentication.',
      );

  @override
  Future<void> confirmPhone(String phone, String code) async =>
      throw const MerchantException(
        'Your phone is already verified through Firebase Authentication.',
      );

  MerchantRequest _request(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return MerchantRequest(
      id: doc.id,
      brand: _string(d, 'brand'),
      title: _string(d, 'title'),
      kind: _enum(RequestKind.values, d['kind'], 'kind'),
      status: _enum(RequestStatus.values, d['status'], 'status'),
      date: _date(d['date'] ?? d['createdAt'], 'date'),
      category: _string(d, 'category'),
      description: _string(d, 'description'),
    );
  }

  MerchantOffer _offer(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return MerchantOffer(
      id: doc.id,
      brand: _string(d, 'brand'),
      title: _string(d, 'title'),
      description: _string(d, 'description'),
      rewardRupees: _integer(d, 'rewardRupees'),
      expiresAt: _date(d['expiresAt'], 'expiresAt'),
      decision: d['decision'] == null
          ? null
          : _enum(OfferDecision.values, d['decision'], 'decision'),
    );
  }

  PaymentRecord _payment(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return PaymentRecord(
      id: doc.id,
      from: _string(d, 'from'),
      description: _string(d, 'description'),
      amountPaise: _integer(d, 'amountPaise'),
      date: _date(d['date'] ?? d['createdAt'], 'date'),
      status: _enum(RecordStatus.values, d['status'], 'status'),
      method: d['method'] as String? ?? 'Not provided',
    );
  }

  InteractionDay _interaction(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return InteractionDay(
      _date(d['date'], 'date'),
      _integer(d, 'views'),
      _integer(d, 'productTaps'),
      _integer(d, 'offerOpens'),
    );
  }

  Conversation _conversation(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) {
    final d = doc.data();
    return Conversation(
      id: doc.id,
      name: _string(d, 'name'),
      role: _enum(ChatRole.values, d['role'], 'role'),
      unread: _integer(d, 'unread', fallback: 0),
      messages: messages.map((message) {
        final m = message.data();
        return ChatMessage(
          id: message.id,
          text: _string(m, 'text'),
          sentAt: _date(m['sentAt'], 'sentAt'),
          fromMerchant:
              m['senderId'] == merchantId || m['fromMerchant'] == true,
        );
      }).toList(),
    );
  }

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('missing $key');
  }

  static int _integer(Map<String, dynamic> data, String key, {int? fallback}) {
    final value = data[key];
    if (value is num) return value.toInt();
    if (fallback != null && value == null) return fallback;
    throw FormatException('missing $key');
  }

  static DateTime _date(Object? value, String key) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw FormatException('missing $key');
  }

  static T _enum<T extends Enum>(List<T> values, Object? value, String key) {
    if (value is String) {
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
    }
    throw FormatException('invalid $key');
  }

  static String _firebaseMessage(String code) => switch (code) {
    'permission-denied' =>
      'You no longer have access to this anchor data. Refresh access or contact support.',
    'unavailable' || 'deadline-exceeded' =>
      'Anchor data is temporarily unavailable. Check your connection and try again.',
    'failed-precondition' =>
      'Firebase needs an index for this anchor query. Ask the administrator to deploy the required indexes.',
    'not-found' => 'The merchant database or record is not available.',
    _ => 'Could not load or save anchor data. Please try again.',
  };
}
