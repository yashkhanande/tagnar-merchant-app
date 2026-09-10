import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/data/firestore_merchant_repository.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../auth/merchant_session_controller.dart';
import '../shell/merchant_shell.dart';

class LiveMerchantShell extends StatelessWidget {
  const LiveMerchantShell({super.key, required this.controller});

  final MerchantSessionController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.identity!;
    final anchor = controller.selectedAnchor;
    if (anchor != null && controller.accessError == null) {
      return MerchantShell(
        key: ValueKey(anchor.id),
        live: true,
        anchors: controller.anchors,
        selectedAnchor: anchor,
        onAnchorSelected: controller.selectAnchor,
        repository: FirestoreMerchantRepository(
          firestore: FirebaseFirestore.instanceFor(
            app: FirebaseAuth.instance.app,
          ),
          functions: FirebaseFunctions.instanceFor(
            app: FirebaseAuth.instance.app,
            region: 'asia-south1',
          ),
          auth: FirebaseAuth.instance,
          merchantId: user.uid,
          merchantName: user.name,
          anchorId: anchor.id,
          anchorName: anchor.name,
          anchorLocation: anchor.location,
          phone: user.verifiedPhone!,
        ),
        onSignOut: controller.signOut,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagnar Merchant'),
        actions: [
          IconButton(
            tooltip: 'Refresh anchor access',
            onPressed: controller.loadingAnchors
                ? null
                : controller.refreshAccess,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: controller.signingOut ? null : controller.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: FeatureList(
          children: [
            const Notice('Firebase connected · Your merchant account'),
            SectionTitle(
              'Hello, ${user.name.split(' ').first}',
              subtitle: 'Your anchor is linked using your merchant ID.',
            ),
            if (controller.loadingAnchors)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (controller.accessError != null)
              EmptyState(
                title: 'Anchor access unavailable',
                message: controller.accessError!,
                icon: Icons.lock_outline,
                action: FilledButton(
                  onPressed: controller.refreshAccess,
                  child: const Text('Try again'),
                ),
              ),
            if (!controller.loadingAnchors &&
                controller.accessError == null &&
                controller.anchors.isEmpty)
              EmptyState(
                title: 'No anchor linked to this merchant',
                message:
                    'Add this merchant UID to the merchantId field of an anchor document.',
                icon: Icons.view_in_ar_outlined,
                action: Column(
                  children: [
                    const Text('Merchant UID'),
                    SelectableText(user.uid),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: controller.refreshAccess,
                      child: const Text('Check for anchors'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
