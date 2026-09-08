import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/features/access/access_repository.dart';
import 'package:tagnar_merchant/features/auth/auth_repository.dart';
import 'package:tagnar_merchant/features/auth/merchant_auth_gate.dart';
import 'package:tagnar_merchant/features/auth/merchant_session_controller.dart';
import 'package:tagnar_merchant/pages/widgets/dashboard_theme.dart';
import 'package:tagnar_merchant/models/onboarding_details.dart';
import 'package:tagnar_merchant/models/merchant.dart';

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
const anchor = MerchantAnchor(
  id: 'anchor-a',
  name: 'Building',
  latitude: 18.4616,
  longitude: 73.8818,
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
  final stream = StreamController<AnchorAccessSnapshot>.broadcast();
  bool profileCompleted = true;
  int profiles = 0;
  @override
  Future<MerchantProfile> ensureProfile(MerchantIdentity identity) async {
    profiles++;
    return MerchantProfile(
      onboardingCompleted: profileCompleted,
      details: const OnboardingDetails(),
    );
  }

  @override
  Future<void> saveOnboarding(String uid, OnboardingDetails details) async {
    profileCompleted = true;
  }

  @override
  Stream<AnchorAccessSnapshot> watchAnchors(String uid) => stream.stream;
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

  test(
    'Google sign-in saves the profile but never opens merchant access',
    () async {
      auth.stream.add(unverified);
      await tick();
      expect(controller.identity!.hasVerifiedPhone, isFalse);
      expect(access.profiles, 1);
      await controller.sendCode('+919000000001');
      await controller.verifyCode('654321');
      await tick();
      expect(controller.identity!.uid, 'alice');
      expect(access.profiles, 2);
    },
  );
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
  test('server anchor opens access; cache-only data clears access', () async {
    auth.stream.add(verified);
    await tick();
    access.stream.add(
      const AnchorAccessSnapshot([anchor], serverConfirmed: true),
    );
    await tick();
    expect(controller.selectedAnchor?.id, 'anchor-a');
    access.stream.add(
      const AnchorAccessSnapshot([anchor], serverConfirmed: false),
    );
    await tick();
    expect(controller.selectedAnchor, isNull);
    expect(controller.anchors, isEmpty);
  });
  test('anchor access is cleared after sign-out', () async {
    auth.stream.add(verified);
    await tick();
    access.stream.add(
      const AnchorAccessSnapshot([anchor], serverConfirmed: true),
    );
    await tick();
    await controller.signOut();
    await tick();
    expect(controller.selectedAnchor, isNull);
    expect(controller.anchors, isEmpty);
  });
  test('anchor revocation never retains active access', () async {
    auth.stream.add(verified);
    await tick();
    access.stream.add(
      const AnchorAccessSnapshot([anchor], serverConfirmed: true),
    );
    await tick();
    access.stream.add(const AnchorAccessSnapshot([], serverConfirmed: true));
    await tick();
    expect(controller.selectedAnchor, isNull);
    expect(controller.anchors, isEmpty);
  });
  test('100 anchors and switching use the selected anchor', () async {
    auth.stream.add(verified);
    await tick();
    final anchors = List.generate(
      100,
      (i) => MerchantAnchor(id: 'anchor-$i', name: 'Anchor $i'),
    );
    access.stream.add(AnchorAccessSnapshot(anchors, serverConfirmed: true));
    await tick();
    controller.selectAnchor(anchors.last);
    expect(controller.anchors.length, 100);
    expect(controller.selectedAnchor?.id, 'anchor-99');
  });

  testWidgets(
    'live UI requires Google, SMS and onboarding before anchor access',
    (tester) async {
      // This widget owns its own controller; the fixture controller remains idle.
      await tester.pumpWidget(
        GetMaterialApp(
          theme: DashboardTheme.data,
          home: MerchantAuthGate(auth: auth, access: access),
        ),
      );
      auth.stream.add(null);
      access.profileCompleted = false;
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
      expect(find.text('Complete your merchant profile'), findsOneWidget);
      for (final label in [
        'Business name',
        'Business address',
        'GST number',
        'City',
        'State',
        'Country',
        'Postal code',
      ]) {
        final field = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, 'Valid value');
      }
      final businessType = find.byType(DropdownButtonFormField<BusinessType>);
      await tester.ensureVisible(businessType);
      await tester.tap(businessType);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sole proprietorship').last);
      await tester.pumpAndSettle();
      final save = find.text('Save and continue');
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(save);
      await tester.pump();
      access.stream.add(const AnchorAccessSnapshot([], serverConfirmed: true));
      await tester.pumpAndSettle();
      expect(find.text('No anchor linked to this merchant'), findsOneWidget);
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('DEMO MODE · Sample data, saved locally'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
