import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../shell/merchant_controller.dart';

class MerchantProfilePage extends StatelessWidget {
  const MerchantProfilePage({super.key, required this.controller});
  final MerchantController controller;
  @override
  Widget build(BuildContext context) {
    final profile = controller.data!.profile;
    return FeatureList(
      children: [
        const SectionTitle(
          'Your merchant profile',
          subtitle: 'One merchant, one shop anchor.',
        ),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                child: Icon(Icons.storefront_outlined, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              DetailLine('Shop', profile.shop),
              DetailLine('Location', profile.address),
              DetailLine('Merchant ID', profile.merchantId),
              DetailLine('Associated anchor', profile.anchorId),
              const Notice(
                'This demo merchant has exactly one fixed shop anchor.',
              ),
            ],
          ),
        ),
        const SectionTitle('Phone confirmation'),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                profile.phoneConfirmed ? 'Demo confirmed' : 'Not confirmed',
              ),
              DetailLine('Phone number', profile.phone),
              const Notice(
                'SMS OTP is planned. In this demo no SMS is sent and no real phone ownership is verified.',
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PhoneConfirmationPage(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.phone_android),
                label: Text(
                  profile.phoneConfirmed
                      ? 'Change demo phone'
                      : 'Confirm phone number',
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('About this preview'),
        const DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailLine(
                'Stage 1',
                'Merchant UI with realistic local demo data',
              ),
              DetailLine(
                'Saved on this device',
                'Offer decisions, messages, read state and demo phone confirmation',
              ),
              DetailLine(
                'Try different states',
                'Use Demo tools in the top bar for loading, empty and error previews. These previews do not delete saved data.',
              ),
              Notice(
                'Firebase authentication, real SMS, chat delivery, notifications, payment records and analytics integrations are later stages.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PhoneConfirmationPage extends StatefulWidget {
  const PhoneConfirmationPage({super.key, required this.controller});
  final MerchantController controller;
  @override
  State<PhoneConfirmationPage> createState() => _PhoneConfirmationPageState();
}

class _PhoneConfirmationPageState extends State<PhoneConfirmationPage> {
  late final TextEditingController _phone;
  final _code = TextEditingController();
  bool _requested = false;
  bool _confirmed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.controller.data!.profile.phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() => _error = null);
    final error = await widget.controller.perform(
      'phone',
      () => widget.controller.repository.requestPhoneCode(_phone.text.trim()),
    );
    if (mounted) {
      setState(() {
        _error = error;
        if (error == null) {
          _requested = true;
          _code.clear();
        }
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    final error = await widget.controller.perform(
      'phone',
      () => widget.controller.repository.confirmPhone(
        _phone.text.trim(),
        _code.text.trim(),
      ),
    );
    if (mounted) {
      setState(() {
        _error = error;
        _confirmed = error == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MerchantController>(
    init: widget.controller,
    global: false,
    builder: (c) {
      final busy = c.busy('phone');
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm phone number')),
        body: SafeArea(
          child: FeatureList(
            children: [
              const SectionTitle('Keep your number up to date'),
              const Notice(
                'DEMO ONLY · No SMS will be sent. This does not verify your identity.',
              ),
              if (_confirmed)
                EmptyState(
                  title: 'Phone confirmed in demo',
                  message: '${_phone.text.trim()} is saved on this device.',
                  icon: Icons.check_circle_outline,
                  action: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to profile'),
                  ),
                )
              else
                DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        enabled: !busy,
                        onChanged: (_) => setState(() {
                          _requested = false;
                          _error = null;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Phone with country code',
                          hintText: '+919876543210',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: busy ? null : _request,
                        child: Text(
                          _requested ? 'Resend demo code' : 'Get demo code',
                        ),
                      ),
                      if (_requested) ...[
                        const Notice(
                          'Demo code: 123456 · Valid for 5 minutes.',
                        ),
                        TextField(
                          controller: _code,
                          enabled: !busy,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-digit demo code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: busy ? null : _confirm,
                          child: const Text('Confirm demo code'),
                        ),
                      ],
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null) Notice(_error!, error: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
