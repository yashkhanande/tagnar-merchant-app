import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../shared/widgets/merchant_widgets.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key, required this.data});
  final MerchantSnapshot data;
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int? _days = 30;
  DateTimeRange? _custom;
  RecordStatus? _status;
  @override
  Widget build(BuildContext context) {
    final dated = widget.data.payments
        .where((p) => inDateRange(p.date, _days, _custom))
        .toList();
    final records = dated
        .where((p) => _status == null || p.status == _status)
        .toList();
    final total = dated
        .where((p) => p.status == RecordStatus.received)
        .fold(0, (sum, p) => sum + p.amountPaise);
    return FeatureList(
      children: [
        const SectionTitle(
          'Payment received',
          subtitle: 'A clear view of your payment records.',
        ),
        const Notice(
          'Demo records only. No real payments are collected or verified.',
        ),
        DateFilter(
          days: _days,
          custom: _custom,
          onChanged: (days, range) => setState(() {
            _days = days;
            _custom = range;
          }),
        ),
        MetricCard(
          label: 'Received in selected period',
          value: money(total),
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 20),
        FilterChips<RecordStatus?>(
          values: [null, ...RecordStatus.values],
          selected: _status,
          label: (s) => s?.label ?? 'All statuses',
          onChanged: (s) => setState(() => _status = s),
        ),
        Text('${records.length} transactions'),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const EmptyState(
            title: 'No transactions found',
            message: 'Try another date range or status.',
          ),
        ...records.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaymentTile(
              payment: p,
              anchorId: widget.data.profile.anchorId,
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment, required this.anchorId});
  final PaymentRecord payment;
  final String anchorId;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () => showDetails(
      context,
      title: 'Transaction details',
      children: [
        Text(
          money(payment.amountPaise),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(payment.status.label),
        ),
        DetailLine('From', payment.from),
        DetailLine('Transaction ID', payment.id),
        DetailLine(
          'Recorded at',
          '${dateLabel(payment.date)} · ${timeLabel(payment.date)}',
        ),
        DetailLine('Description', payment.description),
        DetailLine('Method', payment.method),
        DetailLine('Shop anchor', anchorId),
        const Notice(
          'Sample record. Status comes from demo data; it cannot be changed here.',
        ),
      ],
    ),
    child: DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.from,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            money(payment.amountPaise),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(payment.status.label),
              Text(dateLabel(payment.date)),
            ],
          ),
        ],
      ),
    ),
  );
}
