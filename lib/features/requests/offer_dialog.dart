import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../shell/merchant_controller.dart';

Future<void> showOffer(
  BuildContext context,
  MerchantController controller,
  MerchantOffer offer,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => OfferDialog(controller: controller, offer: offer),
);

class OfferDialog extends StatefulWidget {
  const OfferDialog({super.key, required this.controller, required this.offer});
  final MerchantController controller;
  final MerchantOffer offer;
  @override
  State<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<OfferDialog> {
  String? _error;
  OfferDecision? _savedDecision;
  Future<void> _respond(OfferDecision decision) async {
    setState(() => _error = null);
    final error = await widget.controller.perform(
      widget.offer.id,
      () => widget.controller.repository.respondToOffer(
        widget.offer.id,
        decision,
      ),
    );
    if (!mounted) return;
    setState(() {
      _error = error;
      if (error == null) _savedDecision = decision;
    });
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MerchantController>(
    init: widget.controller,
    global: false,
    builder: (c) {
      final matches = c.data?.offers.where((o) => o.id == widget.offer.id);
      final offer = matches == null || matches.isEmpty
          ? widget.offer
          : matches.first;
      final decision = _savedDecision ?? offer.decision;
      final busy = c.busy(offer.id);
      return PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: Text(
            decision == null
                ? 'Incoming offer'
                : 'Offer ${decision.label.toLowerCase()}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(decision?.label ?? 'Incoming'),
                const SizedBox(height: 18),
                Text(
                  offer.brand,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  offer.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Text(offer.description),
                DetailLine('Sample reward', money(offer.rewardRupees * 100)),
                DetailLine(
                  'Expires',
                  '${dateLabel(offer.expiresAt)} · ${timeLabel(offer.expiresAt)}',
                ),
                DetailLine('Anchor', c.data!.profile.anchorId),
                if (decision != null)
                  const Notice(
                    'Response saved on this device. You cannot respond again.',
                    icon: Icons.check_circle_outline,
                  )
                else
                  const Notice(
                    'Demo offer. Your response stays on this device.',
                  ),
                if (_error != null) Notice(_error!, error: true),
                if (busy)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Saving offer response',
                  ),
              ],
            ),
          ),
          actions: decision != null || !offer.canRespond(DateTime.now())
              ? [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => _respond(OfferDecision.declined),
                    child: const Text('Decline'),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => _respond(OfferDecision.accepted),
                    child: const Text('Accept'),
                  ),
                ],
        ),
      );
    },
  );
}
