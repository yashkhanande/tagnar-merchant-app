import 'package:flutter/material.dart';

import '../../models/merchant_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_theme.dart';

class RecentPayments extends StatelessWidget {
  final List<DashboardPayment> payments;
  final VoidCallback? onViewAll;
  final ValueChanged<DashboardPayment>? onPaymentTap;

  const RecentPayments({
    super.key,
    required this.payments,
    this.onViewAll,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePayments = payments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Recent payments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        DashboardCard(
          child: visiblePayments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No payments in this period.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DashboardTheme.secondary),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visiblePayments.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 28, color: DashboardTheme.border),
                      _PaymentTile(
                        payment: visiblePayments[i],
                        onTap: onPaymentTap == null
                            ? null
                            : () => onPaymentTap!(visiblePayments[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final DashboardPayment payment;
  final VoidCallback? onTap;

  const _PaymentTile({required this.payment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = payment.createdAt.toLocal();

    final dateLabel = localizations.formatMediumDate(date);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    final String statusLabel;
    final Color statusColor;

    switch (payment.status) {
      case PaymentStatus.received:
        statusLabel = 'Received';
        statusColor = const Color(0xFF86EFAC);
        break;
      case PaymentStatus.pending:
        statusLabel = 'Pending';
        statusColor = const Color(0xFFFDE68A);
        break;
      case PaymentStatus.failed:
        statusLabel = 'Failed';
        statusColor = const Color(0xFFFCA5A5);
        break;
      case PaymentStatus.refunded:
        statusLabel = 'Refunded';
        statusColor = DashboardTheme.secondary;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payment.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '$dateLabel · $timeLabel',
              style: const TextStyle(
                color: DashboardTheme.secondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  payment.amountLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(statusLabel, style: TextStyle(color: statusColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
