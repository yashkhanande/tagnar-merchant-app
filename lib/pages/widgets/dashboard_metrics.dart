import 'package:flutter/material.dart';

import '../../models/merchant_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_theme.dart';

class DashboardMetrics extends StatelessWidget {
  final MerchantDashboard data;

  const DashboardMetrics({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Metric(
        title: 'Payments received',
        value: data.receivedLabel,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _Metric(
        title: 'Pending payments',
        value: data.pendingLabel,
        icon: Icons.schedule_rounded,
      ),
      _Metric(
        title: 'Completed orders',
        value: MaterialLocalizations.of(
          context,
        ).formatDecimal(data.completedOrders),
        icon: Icons.shopping_bag_outlined,
      ),
      _Metric(
        title: 'Average order value',
        value: data.averageOrderLabel,
        icon: Icons.insights_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;

        final columns = largeText
            ? 1
            : constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;

        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Metric({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DashboardTheme.accent),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: DashboardTheme.secondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
