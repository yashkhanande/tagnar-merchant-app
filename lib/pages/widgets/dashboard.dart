import 'package:flutter/material.dart';

import '../../models/merchant_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_metrics.dart';
import 'dashboard_theme.dart';
import 'recent_payments.dart';

class Dashboard extends StatefulWidget {
  final String merchantId;
  final DashboardLoader? loader;
  final VoidCallback? onViewAllPayments;
  final ValueChanged<DashboardPayment>? onPaymentTap;

  const Dashboard({
    super.key,
    required this.merchantId,
    this.loader,
    this.onViewAllPayments,
    this.onPaymentTap,
  });

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  DashboardPeriod _period = DashboardPeriod.month;
  MerchantDashboard? _data;
  String? _error;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(covariant Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.merchantId != widget.merchantId ||
        oldWidget.loader != widget.loader) {
      refresh(clearPrevious: true);
    }
  }

  Future<void> refresh({bool clearPrevious = false}) async {
    final request = ++_request;
    final loader = widget.loader;

    setState(() {
      _error = null;
      _loading = loader != null;
      if (clearPrevious || loader == null) _data = null;
    });

    if (loader == null) return;

    try {
      final result = await loader(widget.merchantId, _period);
      if (!mounted || request != _request) return;

      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;

      setState(() {
        _loading = false;
        _error = _data == null
            ? 'Could not load your dashboard.'
            : 'Refresh failed. Previously loaded figures are shown.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Analytics and payments for the selected period.',
          style: TextStyle(color: DashboardTheme.secondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DashboardPeriod.values.map((period) {
            return ChoiceChip(
              label: Text(period.label),
              selected: _period == period,
              onSelected: (selected) {
                if (!selected || _period == period) return;
                setState(() => _period = period);
                refresh(clearPrevious: true);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: LinearProgressIndicator(
              semanticsLabel: 'Loading dashboard',
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!),
                  ),
                  TextButton.icon(
                    onPressed: _loading ? null : () => refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        if (widget.loader == null)
          const DashboardCard(
            child: Text(
              'Analytics will appear here once connected.',
              style: TextStyle(color: DashboardTheme.secondary),
            ),
          ),
        if (data != null) ...[
          DashboardMetrics(data: data),
          const SizedBox(height: 12),
          Text(
            'Updated '
            '${localizations.formatMediumDate(data.updatedAt.toLocal())}'
            ' · '
            '${localizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(data.updatedAt.toLocal()),
              alwaysUse24HourFormat:
                  MediaQuery.of(context).alwaysUse24HourFormat,
            )}',
            style: const TextStyle(
              color: DashboardTheme.secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          RecentPayments(
            payments: data.payments,
            onViewAll: widget.onViewAllPayments,
            onPaymentTap: widget.onPaymentTap,
          ),
        ],
      ],
    );
  }
}