import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/features/access/access_repository.dart';
import 'package:tagnar_merchant/features/auth/auth_repository.dart';
import 'package:tagnar_merchant/features/auth/merchant_auth_gate.dart';
import 'package:tagnar_merchant/features/auth/merchant_session_controller.dart';
import 'package:tagnar_merchant/pages/widgets/dashboard_theme.dart';

const unverified = MerchantIdentity(
  uid: 'alice',
  name: 'Aarav Shah',
  email: 'aarav@example.test',
);
const verified = MerchantIdentity(
  uid: 'alice',
  name: 'Aarav Shah',
  email: 'aarav@example.test',
  verifiedPhone: '+919000000001',
);
const shop = MerchantShop(
  id: 'shop-a',
  name: 'Corner Market',
  address: 'Baner Road, Pune',
  status: 'approved',
  anchorId: 'anchor-a',
);

class FakeAuth implements MerchantAuthRepository {
  final stream = StreamController<MerchantIdentity?>.broadcast();
  void Function(PhoneEvent)? callback;
  int requests = 0, confirmations = 0;
  bool failCode = false;
  @override
  Stream<MerchantIdentity?> get identities => stream.stream;
  @override
  Future<void> signInWithGoogle() async => stream.add(unverified);
  @override
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneEvent) onEvent,
    bool resend = false,
  }) async {
    requests++;
    callback = onEvent;
    onEvent(const PhoneEvent(PhoneEventKind.codeSent));
  }

  @override
  Future<void> confirmPhoneCode(String code) async {
    confirmations++;
    if (failCode || code != '654321') {
      throw const AuthFailure('The SMS code is incorrect. Please try again.');
    }
    stream.add(verified);
  }

  @override
  void cancelPhoneVerification() {}
  @override
  Future<void> refreshIdentity() async {}
  @override
  Future<void> signOut() async => stream.add(null);
}

class FakeAccess implements MerchantAccessRepository {
  final stream = StreamController<ShopAccessSnapshot>.broadcast();
  Completer<ApprovedAnchor>? anchorResult;
  bool deny = false;
  int profiles = 0;
  @override
  Future<void> ensureProfile(MerchantIdentity identity) async {
    profiles++;
  }

  @override
  Stream<ShopAccessSnapshot> watchShops(String uid) => stream.stream;
  @override
  Future<ApprovedAnchor> loadApprovedAnchor({
    required String uid,
    required MerchantShop shop,
  }) async {
    if (deny) throw const AccessFailure('Permission denied');
    return anchorResult?.future ??
        ApprovedAnchor(id: shop.anchorId!, shopId: shop.id, merchantId: uid);
  }
}

Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  late FakeAuth auth;
  late FakeAccess access;
  late MerchantSessionController controller;
  setUp(() {
    auth = FakeAuth();
    access = FakeAccess();
    controller = MerchantSessionController(auth, access)..start();
  });
  tearDown(() async {
    controller.onDelete();
    await auth.stream.close();
    await access.stream.close();
  });

  test('Google sign-in alone never opens merchant access', () async {
    auth.stream.add(unverified);
    await tick();
    expect(controller.identity!.hasVerifiedPhone, isFalse);
    expect(access.profiles, 0);
    await controller.sendCode('+919000000001');
    await controller.verifyCode('654321');
    await tick();
    expect(controller.identity!.uid, 'alice');
    expect(access.profiles, 1);
  });
  test('demo code is not treated as a real SMS code and retry works', () async {
    auth.stream.add(unverified);
    await tick();
    await controller.sendCode('+919000000001');
    await controller.verifyCode('123456');
    expect(controller.error, contains('incorrect'));
    expect(controller.identity!.hasVerifiedPhone, isFalse);
    await controller.verifyCode('654321');
    await tick();
    expect(controller.identity!.hasVerifiedPhone, isTrue);
  });
  test(
    'resend cooldown and stale callback after sign-out are guarded',
    () async {
      auth.stream.add(unverified);
      await tick();
      await controller.sendCode('+919000000001');
      final oldCallback = auth.callback!;
      await controller.sendCode('+919000000001', resend: true);
      expect(auth.requests, 1);
      await controller.signOut();
      await tick();
      oldCallback(const PhoneEvent(PhoneEventKind.codeSent));
      expect(controller.codeSent, isFalse);
      expect(controller.identity, isNull);
    },
  );
  test('automatic SMS timeout still permits manual code entry', () async {
    auth.stream.add(unverified);
    await tick();
    await controller.sendCode('+919000000001');
    auth.callback!(const PhoneEvent(PhoneEventKind.autoRetrievalTimedOut));
    expect(controller.codeSent, isTrue);
    expect(controller.phoneNotice, contains('still enter'));
    await controller.verifyCode('654321');
    await tick();
    expect(controller.identity!.hasVerifiedPhone, isTrue);
  });
  test('server approval opens anchor; cache-only data clears access', () async {
    auth.stream.add(verified);
    await tick();
    access.stream.add(const ShopAccessSnapshot([shop], serverConfirmed: true));
    await tick();
    expect(controller.anchor?.id, 'anchor-a');
    access.stream.add(const ShopAccessSnapshot([shop], serverConfirmed: false));
    await tick();
    expect(controller.anchor, isNull);
    expect(controller.shops, isEmpty);
  });
  test('old account anchor response is ignored after sign-out', () async {
    auth.stream.add(verified);
    await tick();
    access.anchorResult = Completer<ApprovedAnchor>();
    access.stream.add(const ShopAccessSnapshot([shop], serverConfirmed: true));
    await tick();
    await controller.signOut();
    await tick();
    access.anchorResult!.complete(
      const ApprovedAnchor(
        id: 'anchor-a',
        shopId: 'shop-a',
        merchantId: 'alice',
      ),
    );
    await tick();
    expect(controller.anchor, isNull);
    expect(controller.shops, isEmpty);
  });
  test(
    'revocation, access errors and unapproved shops never retain active access',
    () async {
      auth.stream.add(verified);
      await tick();
      access.stream.add(
        const ShopAccessSnapshot([shop], serverConfirmed: true),
      );
      await tick();
      access.stream.add(const ShopAccessSnapshot([], serverConfirmed: true));
      await tick();
      expect(controller.anchor, isNull);
      access.deny = true;
      access.stream.add(
        const ShopAccessSnapshot([shop], serverConfirmed: true),
      );
      await tick();
      expect(controller.anchor, isNull);
      expect(controller.accessError, 'Permission denied');
    },
  );
  test(
    '100 approved shops and switching use the selected shop anchor',
    () async {
      auth.stream.add(verified);
      await tick();
      final shops = List.generate(
        100,
        (i) => MerchantShop(
          id: 'shop-$i',
          name: 'Shop $i',
          address: 'Pune India',
          status: 'approved',
          anchorId: 'anchor-$i',
        ),
      );
      access.stream.add(ShopAccessSnapshot(shops, serverConfirmed: true));
      await tick();
      await controller.selectShop(shops.last);
      expect(controller.shops.length, 100);
      expect(controller.anchor?.id, 'anchor-99');
    },
  );

  testWidgets(
    'live UI requires Google then consent and SMS, and waits for Master assignment',
    (tester) async {
      // This widget owns its own controller; the fixture controller remains idle.
      await tester.pumpWidget(
        GetMaterialApp(
          theme: DashboardTheme.data,
          home: MerchantAuthGate(auth: auth, access: access),
        ),
      );
      auth.stream.add(null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Verify your phone'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Send SMS code'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Phone with country code'),
        '+919000000001',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Send SMS code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'SMS code'),
        '654321',
      );
      await tester.tap(find.text('Verify phone'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      access.stream.add(const ShopAccessSnapshot([], serverConfirmed: true));
      await tester.pumpAndSettle();
      expect(
        find.text('Waiting for a Master to assign your shops'),
        findsOneWidget,
      );
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('DEMO MODE · Sample data, saved locally'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
