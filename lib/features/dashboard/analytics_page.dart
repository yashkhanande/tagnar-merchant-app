import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../pages/widgets/dashboard_theme.dart';
import '../../shared/widgets/merchant_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.interactions});
  final List<InteractionDay> interactions;
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int? _days = 7;
  DateTimeRange? _custom;
  @override
  Widget build(BuildContext context) {
    final days = widget.interactions
        .where((d) => inDateRange(d.date, _days, _custom))
        .toList();
    int total(int Function(InteractionDay) value) =>
        days.fold(0, (sum, d) => sum + value(d));
    return Scaffold(
      appBar: AppBar(title: const Text('User interactions')),
      body: SafeArea(
        child: FeatureList(
          children: [
            const SectionTitle(
              'Understand your shop',
              subtitle: 'See how people explore your anchor.',
            ),
            const Notice(
              'Simulated analytics. Counts are sample events, not unique people or verified sales.',
            ),
            DateFilter(
              days: _days,
              custom: _custom,
              onChanged: (d, r) => setState(() {
                _days = d;
                _custom = r;
              }),
            ),
            MetricGrid(
              children: [
                MetricCard(
                  label: 'Anchor views',
                  value: '${total((d) => d.views)}',
                  icon: Icons.visibility_outlined,
                ),
                MetricCard(
                  label: 'Product taps',
                  value: '${total((d) => d.productTaps)}',
                  icon: Icons.touch_app_outlined,
                ),
                MetricCard(
                  label: 'Offer opens',
                  value: '${total((d) => d.offerOpens)}',
                  icon: Icons.local_offer_outlined,
                ),
              ],
            ),
            const SectionTitle(
              'Daily activity',
              subtitle: 'Anchor views by day',
            ),
            if (days.isEmpty)
              const EmptyState(
                title: 'No activity in this period',
                message: 'Choose another date range.',
              ),
            if (days.isNotEmpty)
              DashboardCard(
                child: Column(
                  children: days.map((d) {
                    final max = days
                        .map((x) => x.views)
                        .reduce((a, b) => a > b ? a : b);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(dateLabel(d.date))),
                              Text('${d.views} views'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label:
                                '${d.views} anchor views on ${dateLabel(d.date)}',
                            child: LinearProgressIndicator(
                              value: max == 0 ? 0 : d.views / max,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              color: DashboardTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${d.productTaps} product taps · ${d.offerOpens} offer opens',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
