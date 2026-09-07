import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../pages/widgets/dashboard_theme.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../payments/payments_page.dart';
import '../requests/offer_dialog.dart';
import '../shell/merchant_controller.dart';
import 'analytics_page.dart';

class MerchantDashboardPage extends StatelessWidget {
  const MerchantDashboardPage({super.key, required this.controller});
  final MerchantController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final received = data.payments
        .where(
          (p) =>
              p.status == RecordStatus.received &&
              inDateRange(p.date, 30, null),
        )
        .fold(0, (sum, p) => sum + p.amountPaise);
    final pending = data.requests
        .where((r) => r.status == RequestStatus.pending)
        .length;
    final active = data.offers.where((o) => o.isActive(DateTime.now())).length;
    final views = data.interactions
        .where((d) => inDateRange(d.date, 7, null))
        .fold(0, (sum, d) => sum + d.views);
    void analytics() => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsPage(interactions: data.interactions),
      ),
    );
    return FeatureList(
      children: [
        const Text(
          'YOUR SHOP, AT A GLANCE',
          style: TextStyle(
            color: DashboardTheme.accent,
            letterSpacing: 1.8,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        SectionTitle(
          'Hello, ${data.profile.name.split(' ').first}',
          subtitle: '${data.profile.shop} · Pune',
        ),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    color: DashboardTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.profile.shop,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const StatusPill('Demo'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'One shop. One anchor.\n${data.profile.anchorId}',
                style: const TextStyle(
                  color: DashboardTheme.secondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MetricGrid(
          children: [
            MetricCard(
              label: 'Received · 30 days',
              value: money(received),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => controller.selectTab(2),
            ),
            MetricCard(
              label: 'Pending requests',
              value: '$pending',
              icon: Icons.inbox_outlined,
              onTap: () => controller.selectTab(1),
            ),
            MetricCard(
              label: 'Active offers',
              value: '$active',
              icon: Icons.local_offer_outlined,
              onTap: () => controller.selectTab(1),
            ),
            MetricCard(
              label: 'Anchor views · 7 days',
              value: '$views',
              icon: Icons.insights,
              onTap: analytics,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...data.offers
            .where((o) => o.canRespond(DateTime.now()))
            .map(
              (o) => DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill('Incoming'),
                    const SizedBox(height: 12),
                    Text(
                      o.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${o.brand} · ${money(o.rewardRupees * 100)} sample reward',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showOffer(context, controller, o),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Review incoming offer'),
                    ),
                  ],
                ),
              ),
            ),
        SectionTitle(
          'User interactions',
          subtitle: 'Sample discovery activity over the last 7 days',
          action: IconButton(
            tooltip: 'View analytics',
            onPressed: analytics,
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$views anchor views',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Explore daily anchor views, product taps and offer opens.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: analytics,
                child: const Text('View interaction analytics'),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Recent payments',
          action: TextButton(
            onPressed: () => controller.selectTab(2),
            child: const Text('View all'),
          ),
        ),
        if (data.payments.isEmpty)
          const EmptyState(
            title: 'No payment records yet',
            message: 'Received-payment records will appear here.',
          ),
        ...data.payments
            .take(3)
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentTile(payment: p, anchorId: data.profile.anchorId),
              ),
            ),
        const Notice(
          'All totals, offers and activity on this dashboard are demo data.',
        ),
      ],
    );
  }
}
