import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../pages/widgets/dashboard_theme.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../access/access_repository.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.interactions,
    this.live = false,
    this.anchors = const [],
    this.selectedAnchorId,
    this.initiallyAllAnchors = false,
  });
  final List<InteractionDay> interactions;
  final bool live;
  final List<MerchantAnchor> anchors;
  final String? selectedAnchorId;
  final bool initiallyAllAnchors;
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int? _days = 7;
  DateTimeRange? _custom;
  String? _anchorId;

  @override
  void initState() {
    super.initState();
    _anchorId = widget.initiallyAllAnchors ? null : widget.selectedAnchorId;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.live && widget.anchors.isNotEmpty) {
      return _liveAnalytics(context);
    }
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
              'Understand your anchor',
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

  Widget _liveAnalytics(BuildContext context) {
    final selected = _anchorId == null
        ? widget.anchors
        : widget.anchors.where((anchor) => anchor.id == _anchorId).toList();
    final views = selected.fold(0, (sum, anchor) => sum + anchor.views);
    final games = selected.fold(0, (sum, anchor) => sum + anchor.gamePlayed);
    final isOverall = _anchorId == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Anchor analytics')),
      body: SafeArea(
        child: FeatureList(
          children: [
            SectionTitle(
              isOverall ? 'All anchor analytics' : selected.first.name,
              subtitle: isOverall
                  ? 'Combined totals for this merchant'
                  : selected.first.displayId,
            ),
            DashboardCard(
              child: DropdownButtonFormField<String>(
                initialValue: _anchorId ?? '__all__',
                decoration: const InputDecoration(
                  labelText: 'Analytics scope',
                  prefixIcon: Icon(Icons.view_in_ar_outlined),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: '__all__',
                    child: Text('All anchors (${widget.anchors.length})'),
                  ),
                  ...widget.anchors.map(
                    (anchor) => DropdownMenuItem<String>(
                      value: anchor.id,
                      child: Text(
                        '${anchor.name} · ${anchor.displayId}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _anchorId = value == '__all__' ? null : value,
                ),
              ),
            ),
            const SizedBox(height: 12),
            MetricGrid(
              children: [
                MetricCard(
                  label: isOverall ? 'Total views' : 'Anchor views',
                  value: '$views',
                  icon: Icons.visibility_outlined,
                ),
                MetricCard(
                  label: 'Games played',
                  value: '$games',
                  icon: Icons.sports_esports_outlined,
                ),
                if (isOverall)
                  MetricCard(
                    label: 'Linked anchors',
                    value: '${selected.length}',
                    icon: Icons.hub_outlined,
                  ),
              ],
            ),
            const Notice(
              'These are lifetime counters from Firebase anchor documents. They cannot be filtered by date unless timestamped interaction events are also recorded.',
            ),
            if (isOverall) ...[
              const SectionTitle(
                'Anchor breakdown',
                subtitle: 'Compare each linked anchor',
              ),
              ...selected.map(
                (anchor) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.view_in_ar_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anchor.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                anchor.displayId,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${anchor.views} views'),
                            const SizedBox(height: 4),
                            Text('${anchor.gamePlayed} games'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SectionTitle('Anchor details'),
              DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailLine('Anchor ID', selected.first.displayId),
                    DetailLine('Location', selected.first.location),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
