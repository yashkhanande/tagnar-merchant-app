import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tagnar_merchant/controller/home_controller.dart';

import '../models/merchant_dashboard.dart';
import 'profile_page.dart';
import 'widgets/dashboard.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/dashboard_theme.dart';
import 'widgets/onboarding.dart';

class HomePage extends GetView<HomeController> {
  final DashboardLoader? loadDashboard;
  final Future<void> Function()? onEditBusiness;
  final VoidCallback? onViewAllPayments;
  final ValueChanged<DashboardPayment>? onPaymentTap;

  const HomePage({
    super.key,
    this.loadDashboard,
    this.onEditBusiness,
    this.onViewAllPayments,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.data,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => Get.to<void>(() => const ProfilePage()),
              icon: const Icon(Icons.account_circle_outlined),
            ),
            Obx(() {
              final refreshing = controller.isRefreshing.value;
              final signedIn = controller.authController.user.value != null;

              return IconButton(
                tooltip: 'Refresh dashboard',
                onPressed: refreshing || !signedIn
                    ? null
                    : controller.refreshDashboard,
                icon: refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              );
            }),
            Obx(() {
              final signingOut = controller.isSigningOut.value;
              final signedIn = controller.authController.user.value != null;

              return IconButton(
                tooltip: 'Sign out',
                onPressed: signingOut || !signedIn ? null : controller.signOut,
                icon: signingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
              );
            }),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            final user = controller.authController.user.value;

            if (user == null) {
              return const Center(
                child: Text('Sign in to view your dashboard.'),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final incomplete =
                              controller.isProfileIncomplete.value;
                          final fields = controller.missingFields.toList();
                          final loading = controller.isLoading.value;
                          final error = controller.profileError.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Onboarding(
                                displayName: controller.displayName,
                                missingFields: incomplete
                                    ? fields
                                    : const <String>[],
                                editing: controller.isEditing.value,
                                onEdit: () => controller.editBusiness(
                                  openEditor: onEditBusiness,
                                ),
                              ),
                              if (loading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: LinearProgressIndicator(
                                    semanticsLabel: 'Loading business profile',
                                  ),
                                ),
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: DashboardCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(error),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: loading
                                              ? null
                                              : () => controller
                                                    .loadMerchantProfile(
                                                      user.uid,
                                                    ),
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                          label: const Text('Try again'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 28),
                        Dashboard(
                          key: controller.dashboardKey,
                          merchantId: user.uid,
                          loader: loadDashboard,
                          onViewAllPayments: onViewAllPayments,
                          onPaymentTap: onPaymentTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
