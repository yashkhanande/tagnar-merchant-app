import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/access/data/firestore_access_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/merchant_auth_gate.dart';
import 'firebase_options.dart';
import 'pages/widgets/dashboard_theme.dart';

/// Isolated from the existing default database used by Unity/other roles.
const merchantDatabaseId = 'tagnar-merchant';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget home;
  try {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('Stage 2 phone verification currently targets Android.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: merchantDatabaseId,
    );
    // Do not retain protected shop records in a persistent offline cache.
    firestore.settings = const Settings(persistenceEnabled: false);
    home = MerchantAuthGate(
      auth: FirebaseMerchantAuthRepository(auth: FirebaseAuth.instance),
      access: FirestoreMerchantAccessRepository(
        firestore: firestore,
        auth: FirebaseAuth.instance,
      ),
    );
  } catch (_) {
    home = const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Could not start Firebase. Run this entry point on Android and follow docs/FIREBASE_SETUP.md, then restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
  runApp(
    GetMaterialApp(
      title: 'Tagnar Merchant',
      debugShowCheckedModeBanner: false,
      theme: DashboardTheme.data,
      home: home,
    ),
  );
}
