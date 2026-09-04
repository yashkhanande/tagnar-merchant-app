import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;

  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardTheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DashboardTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
