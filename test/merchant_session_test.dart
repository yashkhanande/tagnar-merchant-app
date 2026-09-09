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

const verified = MerchantIdentity(
  uid: 'alice',
  name: 'Aarav Shah',
  email: '',
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

Future<void> selectLocation(
  WidgetTester tester,
  String label,
  String value,
) async {
  final dropdown = find.widgetWithText(DropdownButtonFormField<String>, label);
  await tester.ensureVisible(dropdown);
  DropdownButtonFormField<String>? field;
  for (var attempt = 0; attempt < 30; attempt++) {
    field = tester.widget<DropdownButtonFormField<String>>(dropdown);
    if (field.onChanged != null) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  final enabledField = field!;
  expect(
    enabledField.onChanged,
    isNotNull,
    reason: '$label dropdown is disabled.',
  );
  enabledField.onChanged!(value);
  await tester.pump();
}

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

  test('phone verification signs in and creates the profile', () async {
    auth.stream.add(null);
    await tick();
    expect(controller.identity, isNull);
    expect(access.profiles, 0);
    await controller.sendCode('+919000000001');
    await controller.verifyCode('654321');
    await tick();
    expect(controller.identity!.uid, 'alice');
    expect(access.profiles, 1);
  });
  test('demo code is not treated as a real SMS code and retry works', () async {
    auth.stream.add(null);
    await tick();
    await controller.sendCode('+919000000001');
    await controller.verifyCode('123456');
    expect(controller.error, contains('incorrect'));
    expect(controller.identity, isNull);
    await controller.verifyCode('654321');
    await tick();
    expect(controller.identity!.hasVerifiedPhone, isTrue);
  });
  test(
    'resend cooldown and stale callback after sign-out are guarded',
    () async {
      auth.stream.add(null);
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
    auth.stream.add(null);
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

  test('anchor Firebase fields map to merchant analytics counters', () {
    final parsed = MerchantAnchor.fromMap('firebase-document-id', const {
      'anchorId': 'ANC-000003',
      'prefabName': 'Building',
      'latitude': 18.461601504236114,
      'longitude': 73.88180252438978,
      'views': 12,
      'gamePlayed': 4,
      'sensorData': {'isLocationReady': true},
    });

    expect(parsed.id, 'firebase-document-id');
    expect(parsed.displayId, 'firebase-document-id');
    expect(parsed.name, 'Building');
    expect(parsed.views, 12);
    expect(parsed.gamePlayed, 4);
    expect(parsed.location, '18.461602, 73.881803');
  });

  testWidgets('live UI requires SMS and onboarding before anchor access', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // This widget owns its own controller; the fixture controller remains idle.
    await tester.pumpWidget(
      GetMaterialApp(
        theme: DashboardTheme.data,
        home: MerchantAuthGate(auth: auth, access: access),
      ),
    );
    auth.stream.add(null);
    access.profileCompleted = false;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to your merchant workspace'), findsOneWidget);
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
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final sendCode = find.text('Send SMS code');
    await tester.ensureVisible(sendCode);
    await tester.tap(sendCode);
    await tester.pumpAndSettle();
    final smsCode = find.widgetWithText(TextField, 'SMS code');
    await tester.ensureVisible(smsCode);
    await tester.enterText(smsCode, '654321');
    final verifyPhone = find.text('Verify phone');
    await tester.ensureVisible(verifyPhone);
    await tester.tap(verifyPhone);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Complete your merchant profile'), findsOneWidget);
    for (final label in [
      'Business name',
      'Business address',
      'GST number',
      'Postal code',
    ]) {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Valid value');
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await selectLocation(tester, 'Country', 'India');
    await selectLocation(tester, 'State', 'Maharashtra');
    await selectLocation(tester, 'City', 'Amravati');
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
  });
}
