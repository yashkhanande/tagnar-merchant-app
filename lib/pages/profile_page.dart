import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_controller.dart';
import '../controller/home_controller.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/dashboard_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final homeController = Get.find<HomeController>();

    return Theme(
      data: DashboardTheme.data,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            final user = authController.user.value;
            final loading = authController.isLoading.value;

            if (user == null) {
              return const Center(child: Text('You are signed out.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeader(user: user),
                      const SizedBox(height: 20),
                      const _SectionLabel('Account information'),
                      const SizedBox(height: 10),
                      DashboardCard(
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Name',
                              value: _displayName(user),
                            ),
                            const Divider(height: 32),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: user.email ?? 'Not available',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Business'),
                      const SizedBox(height: 10),
                      DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      DashboardTheme.iconBackground,
                                  child: Icon(
                                    Icons.storefront_outlined,
                                    color: DashboardTheme.accent,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Business details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'View or update your merchant profile',
                                        style: TextStyle(
                                          color: DashboardTheme.secondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: homeController.isEditing.value
                                    ? null
                                    : homeController.editBusiness,
                                icon: homeController.isEditing.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.visibility_outlined),
                                label: Text(
                                  homeController.isEditing.value
                                      ? 'Opening...'
                                      : 'View business details',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      DashboardCard(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: loading
                                    ? null
                                    : authController.signOut,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign out'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: loading
                                    ? null
                                    : authController.deleteAccount,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFCA5A5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Delete account'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  static String _displayName(User user) {
    final name = user.displayName?.trim();
    return name == null || name.isEmpty ? 'Merchant' : name;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: DashboardTheme.secondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = ProfilePage._displayName(user);

    return DashboardCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: DashboardTheme.iconBackground,
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: DashboardTheme.accent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'Merchant account',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DashboardTheme.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: DashboardTheme.iconBackground,
          child: Icon(icon, size: 20, color: DashboardTheme.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: DashboardTheme.secondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
