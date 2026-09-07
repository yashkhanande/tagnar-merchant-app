import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../pages/widgets/dashboard_theme.dart';

class FeatureList extends StatelessWidget {
  const FeatureList({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(color: DashboardTheme.secondary),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.error = false,
  });
  final String text;
  final IconData icon;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline : icon,
          size: 18,
          color: error
              ? Theme.of(context).colorScheme.error
              : DashboardTheme.accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: error,
            child: Text(
              text,
              style: TextStyle(
                color: error
                    ? Theme.of(context).colorScheme.error
                    : DashboardTheme.secondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: DashboardCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: DashboardTheme.accent),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DashboardTheme.secondary),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final color = switch (text.toLowerCase()) {
      'received' ||
      'approved' ||
      'accepted' ||
      'active' => const Color(0xFF94E8C2),
      'pending' || 'incoming' => const Color(0xFFFFD68B),
      'failed' || 'declined' => const Color(0xFFFFAFB1),
      _ => DashboardTheme.accent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DashboardTheme.accent, size: 22),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: DashboardTheme.secondary),
            ),
          ],
        ),
      ),
    ),
  );
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final single =
          constraints.maxWidth < 310 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4;
      final width = single
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: values
          .map(
            (v) => ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              onSelected: (_) => onChanged(v),
            ),
          )
          .toList(),
    ),
  );
}

class DateFilter extends StatelessWidget {
  const DateFilter({
    super.key,
    required this.days,
    required this.custom,
    required this.onChanged,
  });
  final int? days;
  final DateTimeRange? custom;
  final void Function(int? days, DateTimeRange? custom) onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FilterChips<int>(
        values: const [1, 7, 30, 0, -1],
        selected: custom != null ? -1 : days ?? 0,
        label: (v) => switch (v) {
          1 => 'Today',
          7 => '7 days',
          30 => '30 days',
          -1 => 'Custom',
          _ => 'All time',
        },
        onChanged: (v) async {
          if (v != -1) {
            onChanged(v == 0 ? null : v, null);
            return;
          }
          final now = DateTime.now();
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 5),
            lastDate: now,
            initialDateRange: custom,
            helpText: 'Choose a date range',
          );
          if (range != null && context.mounted) onChanged(null, range);
        },
      ),
      if (custom != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${dateLabel(custom!.start)} – ${dateLabel(custom!.end)}',
          ),
        ),
    ],
  );
}

bool inDateRange(
  DateTime value,
  int? days,
  DateTimeRange? custom, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final start =
      custom?.start ??
      (days == null
          ? null
          : DateTime(today.year, today.month, today.day - days + 1));
  final last = custom?.end ?? today;
  final end = DateTime(last.year, last.month, last.day + 1);
  return (start == null || !value.isBefore(start)) && value.isBefore(end);
}

void showDetails(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [SectionTitle(title), ...children],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: DashboardTheme.secondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
}
