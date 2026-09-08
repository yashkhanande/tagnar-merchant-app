import 'dart:convert';

import '../merchant_repository.dart';
import '../models.dart';
import 'demo_fixtures.dart';
import 'demo_store.dart';

class DemoMerchantRepository implements MerchantRepository {
  DemoMerchantRepository(
    this.store, {
    DateTime Function()? clock,
    this.delay = const Duration(milliseconds: 350),
  }) : clock = clock ?? DateTime.now;
  final DemoStore store;
  final DateTime Function() clock;
  final Duration delay;
  late MerchantSnapshot _seed;
  bool _initialized = false;
  Map<String, dynamic> _saved = {};
  Future<void> _queue = Future<void>.value();
  String? _requestedPhone;
  DateTime? _codeExpires;

  // Serialize reads/writes so concurrent taps cannot overwrite decisions or
  // lose messages. Publish changes only after local storage succeeds.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) async {
      await Future<void>.delayed(delay);
      await _initialize();
      return action();
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    final raw = await store.read();
    _saved = raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
    final base = _saved['fixtureDate'] as String?;
    _seed = demoFixtures(base == null ? clock() : DateTime.parse(base));
    if (base == null) {
      await _commit({..._saved, 'fixtureDate': clock().toIso8601String()});
    }
    _initialized = true;
  }

  Future<void> _commit(Map<String, dynamic> next) async {
    await store.write(jsonEncode(next));
    _saved = next;
  }

  MerchantSnapshot _snapshot({bool empty = false}) {
    final decisions = Map<String, dynamic>.from(
      _saved['decisions'] as Map? ?? {},
    );
    final messages = Map<String, dynamic>.from(
      _saved['messages'] as Map? ?? {},
    );
    final read = List<String>.from(_saved['read'] as List? ?? []);
    return MerchantSnapshot(
      profile: AnchorProfile(
        phone: _saved['phone'] as String? ?? _seed.profile.phone,
        phoneConfirmed: _saved['phone'] != null,
      ),
      requests: empty ? [] : _seed.requests,
      offers: empty
          ? []
          : _seed.offers
                .map(
                  (o) => decisions[o.id] == null
                      ? o
                      : o.withDecision(
                          OfferDecision.values.byName(
                            decisions[o.id] as String,
                          ),
                        ),
                )
                .toList(),
      payments: empty ? [] : _seed.payments,
      interactions: empty ? [] : _seed.interactions,
      conversations: empty
          ? []
          : _seed.conversations
                .map(
                  (c) => c.copy(
                    unread: read.contains(c.id) ? 0 : c.unread,
                    messages: [
                      ...c.messages,
                      ...(messages[c.id] as List? ?? []).map(
                        (m) => ChatMessage.fromJson(
                          Map<String, dynamic>.from(m as Map),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
    );
  }

  @override
  Future<MerchantSnapshot> load({
    DemoScenario scenario = DemoScenario.normal,
  }) => _serialized(() async {
    if (scenario == DemoScenario.error) {
      throw const MerchantException(
        'Demo connection failed. Try again to restore sample data.',
      );
    }
    return _snapshot(empty: scenario == DemoScenario.empty);
  });

  @override
  Future<void> respondToOffer(
    String offerId,
    OfferDecision decision,
  ) => _serialized(() async {
    final offers = _snapshot().offers.where((o) => o.id == offerId);
    if (offers.isEmpty) throw const MerchantException('Offer not found.');
    final offer = offers.single;
    if (offer.decision != null) {
      throw const MerchantException('This offer already has a saved response.');
    }
    if (!offer.canRespond(clock())) {
      throw const MerchantException('This offer has expired.');
    }
    await _commit({
      ..._saved,
      'decisions': {...?_saved['decisions'] as Map?, offerId: decision.name},
    });
  });

  @override
  Future<void> sendMessage(String conversationId, String text) => _serialized(
    () async {
      final value = text.trim();
      if (value.isEmpty || value.length > 1000) {
        throw const MerchantException('Enter a message of 1–1,000 characters.');
      }
      if (!_seed.conversations.any((c) => c.id == conversationId)) {
        throw const MerchantException('Conversation not found.');
      }
      final all = Map<String, dynamic>.from(_saved['messages'] as Map? ?? {});
      final previous = List<dynamic>.from(all[conversationId] as List? ?? []);
      final now = clock();
      previous.add(
        ChatMessage(
          id: '${now.microsecondsSinceEpoch}-${previous.length}',
          text: value,
          sentAt: now,
          fromMerchant: true,
        ).toJson(),
      );
      all[conversationId] = previous;
      await _commit({..._saved, 'messages': all});
    },
  );

  @override
  Future<void> markConversationRead(String conversationId) =>
      _serialized(() async {
        if (!_seed.conversations.any((c) => c.id == conversationId)) {
          throw const MerchantException('Conversation not found.');
        }
        final read = <String>{
          ...List<String>.from(_saved['read'] as List? ?? []),
          conversationId,
        };
        await _commit({..._saved, 'read': read.toList()});
      });

  @override
  Future<void> requestPhoneCode(String phone) => _serialized(() async {
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      throw const MerchantException(
        'Use +, country code, and 8–15 digits, without spaces.',
      );
    }
    _requestedPhone = phone;
    _codeExpires = clock().add(const Duration(minutes: 5));
  });

  @override
  Future<void> confirmPhone(String phone, String code) => _serialized(() async {
    if (_requestedPhone != phone ||
        _codeExpires == null ||
        !clock().isBefore(_codeExpires!)) {
      throw const MerchantException('Request a new demo code for this number.');
    }
    if (code != '123456') {
      throw const MerchantException('Incorrect demo code. Enter 123456.');
    }
    await _commit({..._saved, 'phone': phone});
    _requestedPhone = null;
    _codeExpires = null;
  });
}
