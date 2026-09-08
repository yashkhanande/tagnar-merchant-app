import 'package:flutter_test/flutter_test.dart';
import 'package:tagnar_merchant/core/data/demo_merchant_repository.dart';
import 'package:tagnar_merchant/core/data/demo_store.dart';
import 'package:tagnar_merchant/core/merchant_repository.dart';
import 'package:tagnar_merchant/core/models.dart';

class FailingStore extends MemoryDemoStore {
  bool fail = false;
  @override
  Future<void> write(String value) async {
    if (fail) throw Exception('Disk unavailable');
    await super.write(value);
  }
}

void main() {
  final now = DateTime(2026, 9, 7, 18);
  DemoMerchantRepository repo(DemoStore store) =>
      DemoMerchantRepository(store, clock: () => now, delay: Duration.zero);

  test('one fixed anchor and read-only payment totals', () async {
    final data = await repo(MemoryDemoStore()).load();
    expect(data.profile.anchorId, 'ANCHOR-PN-0142');
    expect(
      data.payments
          .where((p) => p.status == RecordStatus.received)
          .fold(0, (sum, p) => sum + p.amountPaise),
      2825000,
    );
    expect(() => data.payments.clear(), throwsUnsupportedError);
  });

  for (final decision in OfferDecision.values) {
    test(
      '${decision.name} persists across repository recreation and rejects a second response',
      () async {
        final store = MemoryDemoStore();
        final repository = repo(store);
        await repository.respondToOffer('OFF-208', decision);
        final reopened = repo(store);
        expect((await reopened.load()).offers.first.decision, decision);
        await expectLater(
          reopened.respondToOffer('OFF-208', OfferDecision.accepted),
          throwsA(isA<MerchantException>()),
        );
        expect((await reopened.load()).offers.first.decision, decision);
      },
    );
  }

  test('concurrent responses allow exactly one decision', () async {
    final repository = repo(MemoryDemoStore());
    final outcomes = await Future.wait(
      OfferDecision.values.map((d) async {
        try {
          await repository.respondToOffer('OFF-208', d);
          return true;
        } on MerchantException {
          return false;
        }
      }),
    );
    expect(outcomes, [true, false]);
    expect(
      (await repository.load()).offers.first.decision,
      OfferDecision.accepted,
    );
  });

  test(
    'failed persistence does not publish an offer response; retry succeeds',
    () async {
      final store = FailingStore();
      final repository = repo(store);
      await repository.load();
      store.fail = true;
      await expectLater(
        repository.respondToOffer('OFF-208', OfferDecision.accepted),
        throwsException,
      );
      expect((await repository.load()).offers.first.decision, isNull);
      store.fail = false;
      await repository.respondToOffer('OFF-208', OfferDecision.declined);
      expect(
        (await repository.load()).offers.first.decision,
        OfferDecision.declined,
      );
    },
  );

  test('expired and unknown offers cannot be answered', () async {
    final store = MemoryDemoStore();
    await repo(store).load();
    final later = DemoMerchantRepository(
      store,
      clock: () => now.add(const Duration(days: 20)),
      delay: Duration.zero,
    );
    await expectLater(
      later.respondToOffer('OFF-208', OfferDecision.accepted),
      throwsA(isA<MerchantException>()),
    );
    await expectLater(
      later.respondToOffer('missing', OfferDecision.accepted),
      throwsA(isA<MerchantException>()),
    );
  });

  test('local chat send/read persists and validates input', () async {
    final store = MemoryDemoStore();
    final repository = repo(store);
    await repository.sendMessage('chat-brand', '  Hello from my anchor  ');
    await repository.markConversationRead('chat-brand');
    final data = await repo(store).load();
    final chat = data.conversations.first;
    expect(chat.unread, 0);
    expect(chat.messages.last.text, 'Hello from my anchor');
    expect(chat.messages.last.fromMerchant, isTrue);
    expect(data.conversations[1].unread, 1);
    await expectLater(
      repository.sendMessage('chat-brand', '   '),
      throwsA(isA<MerchantException>()),
    );
    await expectLater(
      repository.sendMessage('unknown', 'Hi'),
      throwsA(isA<MerchantException>()),
    );
    await expectLater(
      repository.sendMessage('chat-brand', 'x' * 1001),
      throwsA(isA<MerchantException>()),
    );
  });

  test(
    'demo code is tied to requested phone, expires, and cannot be reused',
    () async {
      final store = MemoryDemoStore();
      var time = now;
      final repository = DemoMerchantRepository(
        store,
        clock: () => time,
        delay: Duration.zero,
      );
      await expectLater(
        repository.confirmPhone('+919876543210', '123456'),
        throwsA(isA<MerchantException>()),
      );
      await expectLater(
        repository.requestPhoneCode('123'),
        throwsA(isA<MerchantException>()),
      );
      await repository.requestPhoneCode('+919876543210');
      await expectLater(
        repository.confirmPhone('+919876543211', '123456'),
        throwsA(isA<MerchantException>()),
      );
      await expectLater(
        repository.confirmPhone('+919876543210', '000000'),
        throwsA(isA<MerchantException>()),
      );
      time = time.add(const Duration(minutes: 6));
      await expectLater(
        repository.confirmPhone('+919876543210', '123456'),
        throwsA(isA<MerchantException>()),
      );
      await repository.requestPhoneCode('+919876543210');
      await repository.confirmPhone('+919876543210', '123456');
      expect((await repo(store).load()).profile.phoneConfirmed, isTrue);
      await expectLater(
        repository.confirmPhone('+919876543210', '123456'),
        throwsA(isA<MerchantException>()),
      );
    },
  );

  test('empty/error previews do not delete saved data', () async {
    final repository = repo(MemoryDemoStore());
    await repository.respondToOffer('OFF-208', OfferDecision.declined);
    final empty = await repository.load(scenario: DemoScenario.empty);
    expect(empty.requests, isEmpty);
    expect(empty.payments, isEmpty);
    expect(empty.conversations, isEmpty);
    expect(empty.interactions, isEmpty);
    await expectLater(
      repository.load(scenario: DemoScenario.error),
      throwsA(isA<MerchantException>()),
    );
    expect(
      (await repository.load()).offers.first.decision,
      OfferDecision.declined,
    );
  });
}
