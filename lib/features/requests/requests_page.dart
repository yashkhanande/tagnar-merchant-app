import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../shell/merchant_controller.dart';
import 'offer_dialog.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key, required this.controller, this.live = false});
  final MerchantController controller;
  final bool live;
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _search = TextEditingController();
  RequestKind? _kind;
  RequestStatus? _status;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data!;
    String placement(MerchantRequest request) =>
        request.targetScope == AnchorTargetScope.single &&
            request.anchorDocumentIds.isEmpty
        ? data.profile.anchorId
        : request.placementLabel;
    final query = _search.text.trim().toLowerCase();
    final requests = data.requests
        .where(
          (r) =>
              (_kind == null || r.kind == _kind) &&
              (_status == null || r.status == _status) &&
              '${r.title} ${r.brand} ${r.id} ${r.category}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return FeatureList(
      children: [
        const SectionTitle(
          'Brands & products',
          subtitle: 'Discover proposals for your anchor.',
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Search requests',
            hintText: 'Brand, product or request ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilterChips<RequestKind?>(
          values: [null, ...RequestKind.values],
          selected: _kind,
          label: (v) => v == null
              ? 'All types'
              : v == RequestKind.brand
              ? 'Brands'
              : 'Products',
          onChanged: (v) => setState(() => _kind = v),
        ),
        FilterChips<RequestStatus?>(
          values: [null, ...RequestStatus.values],
          selected: _status,
          label: (v) => v?.label ?? 'All statuses',
          onChanged: (v) => setState(() => _status = v),
        ),
        Text(
          '${requests.length} requests · ${requests.any((r) => r.isPreview)
              ? 'includes preview data'
              : widget.live
              ? 'Firebase'
              : 'incoming demo proposals'}',
        ),
        const SizedBox(height: 14),
        if (requests.isEmpty)
          EmptyState(
            title: 'No requests found',
            message: 'Try a different search or clear the filters.',
            action: TextButton(
              onPressed: () => setState(() {
                _search.clear();
                _kind = null;
                _status = null;
              }),
              child: const Text('Clear filters'),
            ),
          ),
        ...requests.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showDetails(
                context,
                title: r.title,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(r.isPreview ? 'Preview' : r.status.label),
                  ),
                  DetailLine('Brand', r.brand),
                  DetailLine('Request ID', r.id),
                  DetailLine(
                    'Type / category',
                    '${r.kind.label} · ${r.category}',
                  ),
                  DetailLine('Submitted', dateLabel(r.date)),
                  DetailLine('Requested placement', placement(r)),
                  DetailLine('Proposal', r.description),
                  Notice(
                    r.isPreview
                        ? 'Preview only — this is not stored in Firebase. The Brand app will be able to request one anchor, selected anchors, or all anchors.'
                        : 'This request came from Firebase and targets anchor document IDs.',
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
                            r.brand,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        StatusPill(r.isPreview ? 'Preview' : r.status.label),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      r.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${r.kind.label} · ${r.category}'),
                    const SizedBox(height: 6),
                    Text(
                      placement(r),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${r.id} · ${dateLabel(r.date)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SectionTitle(
          'Offer inbox',
          subtitle: 'Review an offer and save your response.',
        ),
        if (data.offers.isEmpty)
          const EmptyState(
            title: 'No offers yet',
            message: 'Incoming offers will appear here.',
          ),
        ...data.offers.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    o.decision?.label ??
                        (o.canRespond(DateTime.now()) ? 'Incoming' : 'Expired'),
                  ),
                  const SizedBox(height: 12),
                  Text(o.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${o.brand} · ${money(o.rewardRupees * 100)} sample reward',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => showOffer(context, widget.controller, o),
                    child: Text(
                      o.decision == null ? 'Review offer' : 'View response',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
