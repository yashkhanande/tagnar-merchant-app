import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tagnar_merchant/controller/auth_controller.dart';
import 'package:tagnar_merchant/controller/home_controller.dart';
import 'package:tagnar_merchant/pages/profile_page.dart';
import 'package:tagnar_merchant/pages/widgets/complete_profile_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final homeController = Get.find<HomeController>();

    final theme = Theme.of(context);
    final user = authController.user.value;

    Future<void> openProfile() async {
      await Get.to(() => const ProfilePage());

      if (user != null) {
        await homeController.loadMerchantProfile(user.uid);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: authController.signOut,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _WelcomeSection(
                displayName: user?.displayName ?? 'User',
                onTap: openProfile,
              ),

              const SizedBox(height: 24),

              // Complete profile section
              Obx(() {
                final isIncomplete = homeController.isProfileIncomplete.value;

                if (!isIncomplete) {
                  return const SizedBox.shrink();
                }

                return CompleteProfileCard(
                  missingFields: homeController.missingFields,
                  onCompleteProfile: openProfile,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String displayName;
  final VoidCallback onTap;

  const _WelcomeSection({required this.displayName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(
                Icons.storefront_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
