import 'package:flutter/material.dart';

import 'complete_profile_card.dart';
import 'dashboard_card.dart';
import 'dashboard_theme.dart';

class Onboarding extends StatelessWidget {
  final String displayName;
  final List<String> missingFields;
  final VoidCallback onEdit;
  final bool editing;

  const Onboarding({
    super.key,
    required this.displayName,
    required this.missingFields,
    required this.onEdit,
    this.editing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: DashboardTheme.iconBackground,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: DashboardTheme.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: DashboardTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: editing ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  editing ? 'Opening...' : 'Edit business details',
                ),
              ),
            ],
          ),
        ),
        if (missingFields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AbsorbPointer(
              absorbing: editing,
              child: CompleteProfileCard(
                missingFields: missingFields,
                onCompleteProfile: onEdit,
              ),
            ),
          ),
      ],
    );
  }
}