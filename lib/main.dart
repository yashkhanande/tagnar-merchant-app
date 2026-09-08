import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/data/demo_merchant_repository.dart';
import 'core/data/demo_store.dart';
import 'core/merchant_repository.dart';
import 'features/access/data/firestore_access_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/merchant_auth_gate.dart';
import 'features/shell/merchant_shell.dart';
import 'firebase_options.dart';
import 'pages/widgets/dashboard_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget home;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Sideloaded debug APKs are not known to Google Play, so Play Integrity can
    // reject an otherwise correctly signed app. Use Firebase's supported web
    // reCAPTCHA fallback for Android development; release builds retain Play
    // Integrity app verification.
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAuth.instance.setSettings(forceRecaptchaFlow: true);
    }
    final firestore = FirebaseFirestore.instanceFor(app: Firebase.app());
    firestore.settings = const Settings(persistenceEnabled: false);
    home = MerchantAuthGate(
      auth: FirebaseMerchantAuthRepository(auth: FirebaseAuth.instance),
      access: FirestoreMerchantAccessRepository(
        firestore: firestore,
        auth: FirebaseAuth.instance,
      ),
    );
  } catch (_) {
    home = const FirebaseStartupError();
  }
  runApp(LiveApp(home: home));
}

class LiveApp extends StatelessWidget {
  const LiveApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Tagnar Merchant',
    debugShowCheckedModeBanner: false,
    theme: DashboardTheme.data,
    home: home,
  );
}

class FirebaseStartupError extends StatelessWidget {
  const FirebaseStartupError({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Firebase is unavailable. Check this app’s Firebase configuration and your connection, then restart.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});
  final MerchantRepository? repository;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Tagnar Merchant · Demo',
    debugShowCheckedModeBanner: false,
    theme: DashboardTheme.data,
    home: MerchantShell(
      repository: repository ?? DemoMerchantRepository(PreferencesDemoStore()),
    ),
  );
}
