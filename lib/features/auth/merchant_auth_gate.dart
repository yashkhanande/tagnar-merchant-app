import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../access/access_repository.dart';
import '../access/live_merchant_shell.dart';
import 'auth_repository.dart';
import 'merchant_session_controller.dart';
import '../onboarding/merchant_onboarding_page.dart';

class MerchantAuthGate extends StatefulWidget {
  const MerchantAuthGate({super.key, required this.auth, required this.access});
  final MerchantAuthRepository auth;
  final MerchantAccessRepository access;
  @override
  State<MerchantAuthGate> createState() => _MerchantAuthGateState();
}

class _MerchantAuthGateState extends State<MerchantAuthGate>
    with WidgetsBindingObserver {
  late final MerchantSessionController _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MerchantSessionController(widget.auth, widget.access)
      ..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _controller.identity?.hasVerifiedPhone == true) {
      _controller.refreshAccess();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.onDelete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MerchantSessionController>(
    init: _controller,
    global: false,
    builder: (c) {
      if (c.starting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (c.identity != null && c.loadingProfile) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (c.identity != null && !c.profileLoaded) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tagnar Merchant'),
            actions: [
              TextButton(onPressed: c.signOut, child: const Text('Sign out')),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  title: 'Merchant profile unavailable',
                  message:
                      c.accessError ?? 'Could not load your merchant profile.',
                  icon: Icons.person_off_outlined,
                  action: FilledButton(
                    onPressed: c.refreshAccess,
                    child: const Text('Try again'),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (c.identity?.hasVerifiedPhone == true &&
          !c.onboardingCompleted &&
          !c.signingOut) {
        return MerchantOnboardingPage(controller: c);
      }
      if (c.identity?.hasVerifiedPhone == true &&
          c.onboardingCompleted &&
          !c.signingOut) {
        return LiveMerchantShell(controller: c);
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tagnar Merchant'),
          actions: [
            if (c.identity != null)
              TextButton(
                onPressed: c.verifyingCode || c.signingOut ? null : c.signOut,
                child: const Text('Sign out'),
              ),
          ],
        ),
        body: SafeArea(
          child: FeatureList(
            children: [
              if (c.identity == null) ...[
                const SectionTitle(
                  'Welcome to your merchant workspace',
                  subtitle:
                      'Sign in, verify your phone and connect your anchor.',
                ),
                const DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.storefront_outlined, size: 48),
                      SizedBox(height: 20),
                      Text(
                        'Your anchor. One merchant account.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your anchor is connected through its merchantId field.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: c.signingIn ? null : c.signIn,
                  icon: const Icon(Icons.login),
                  label: Text(
                    c.signingIn ? 'Signing in…' : 'Continue with Google',
                  ),
                ),
                if (c.signingIn) const LinearProgressIndicator(),
                const Notice(
                  'This is the Firebase-connected app. For sample data, run the separate demo entry point.',
                ),
              ] else ...[
                SectionTitle(
                  'Verify your phone',
                  subtitle: 'Signed in as ${c.identity!.email}',
                ),
                RealPhoneForm(key: ValueKey(c.identity!.uid), controller: c),
              ],
              if (c.error != null) Notice(c.error!, error: true),
            ],
          ),
        ),
      );
    },
  );
}

class RealPhoneForm extends StatefulWidget {
  const RealPhoneForm({super.key, required this.controller});
  final MerchantSessionController controller;
  @override
  State<RealPhoneForm> createState() => _RealPhoneFormState();
}

class _RealPhoneFormState extends State<RealPhoneForm> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _consent = false;
  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm your phone with an SMS code. Your Google account stays the same.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            enabled: !c.codeSent && !c.sendingCode && !c.verifyingCode,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Phone with country code',
              hintText: '+919876543210',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: c.sendingCode || c.verifyingCode || c.codeSent
                ? null
                : (v) => setState(() => _consent = v ?? false),
            title: const Text(
              'I agree to receive a verification SMS. Google processes and stores my phone number to help prevent spam and abuse.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          if (!c.codeSent)
            FilledButton(
              onPressed: !_consent || c.sendingCode
                  ? null
                  : () => c.sendCode(_phone.text.trim()),
              child: Text(c.sendingCode ? 'Requesting SMS…' : 'Send SMS code'),
            ),
          if (c.sendingCode || c.verifyingCode)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (c.phoneNotice != null) Notice(c.phoneNotice!),
          if (c.codeSent) ...[
            TextField(
              controller: _code,
              enabled: !c.verifyingCode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(
                labelText: 'SMS code',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: c.verifyingCode
                  ? null
                  : () => c.verifyCode(_code.text.trim()),
              child: const Text('Verify phone'),
            ),
            TextButton(
              onPressed: c.verifyingCode || c.resendSeconds > 0
                  ? null
                  : () {
                      _code.clear();
                      c.sendCode(c.requestedPhone, resend: true);
                    },
              child: Text(
                c.resendSeconds > 0
                    ? 'Resend in ${c.resendSeconds}s'
                    : 'Resend SMS code',
              ),
            ),
            TextButton(
              onPressed: c.verifyingCode
                  ? null
                  : () {
                      _code.clear();
                      c.changePhone();
                    },
              child: const Text('Use a different number'),
            ),
          ],
        ],
      ),
    );
  }
}
