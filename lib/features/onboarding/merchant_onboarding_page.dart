import 'package:flutter/material.dart';

import '../../models/merchant.dart';
import '../../models/onboarding_details.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../auth/merchant_session_controller.dart';

class MerchantOnboardingPage extends StatefulWidget {
  const MerchantOnboardingPage({super.key, required this.controller});

  final MerchantSessionController controller;

  @override
  State<MerchantOnboardingPage> createState() => _MerchantOnboardingPageState();
}

class _MerchantOnboardingPageState extends State<MerchantOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  BusinessType _businessType = BusinessType.none;

  @override
  void initState() {
    super.initState();
    final details = widget.controller.onboardingDetails;
    final identity = widget.controller.identity!;
    _businessType = details.businessType;
    _fields = {
      'businessName': TextEditingController(text: details.businessName),
      'businessAddress': TextEditingController(text: details.businessAddress),
      'businessPhone': TextEditingController(
        text: details.businessPhone.isEmpty
            ? identity.verifiedPhone
            : details.businessPhone,
      ),
      'businessEmail': TextEditingController(
        text: details.businessEmail.isEmpty
            ? identity.email
            : details.businessEmail,
      ),
      'gstNumber': TextEditingController(text: details.gstNumber),
      'city': TextEditingController(text: details.city),
      'state': TextEditingController(text: details.state),
      'country': TextEditingController(text: details.country),
      'postalCode': TextEditingController(text: details.postalCode),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _businessType == BusinessType.none) {
      setState(() {});
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.controller.completeOnboarding(
      OnboardingDetails(
        businessName: _fields['businessName']!.text,
        businessAddress: _fields['businessAddress']!.text,
        businessType: _businessType,
        businessPhone: _fields['businessPhone']!.text,
        businessEmail: _fields['businessEmail']!.text,
        gstNumber: _fields['gstNumber']!.text,
        city: _fields['city']!.text,
        state: _fields['state']!.text,
        country: _fields['country']!.text,
        postalCode: _fields['postalCode']!.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.controller.savingOnboarding;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete your merchant profile'),
        actions: [
          TextButton(
            onPressed: saving ? null : widget.controller.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Business details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete these details before accessing your merchant anchor.',
                    ),
                    const SizedBox(height: 20),
                    DashboardCard(
                      child: Column(
                        children: [
                          _field(
                            'businessName',
                            'Business name',
                            Icons.storefront_outlined,
                            saving,
                          ),
                          _field(
                            'businessAddress',
                            'Business address',
                            Icons.location_on_outlined,
                            saving,
                            maxLines: 3,
                          ),
                          DropdownButtonFormField<BusinessType>(
                            key: ValueKey(_businessType),
                            initialValue: _businessType == BusinessType.none
                                ? null
                                : _businessType,
                            decoration: const InputDecoration(
                              labelText: 'Business type',
                              prefixIcon: Icon(Icons.business_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: BusinessType.values
                                .where((type) => type != BusinessType.none)
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(_label(type)),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (value) => setState(
                                    () => _businessType =
                                        value ?? BusinessType.none,
                                  ),
                            validator: (value) => value == null
                                ? 'This field is required.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            'businessPhone',
                            'Business phone',
                            Icons.phone_outlined,
                            saving,
                            keyboard: TextInputType.phone,
                          ),
                          _field(
                            'businessEmail',
                            'Business email',
                            Icons.email_outlined,
                            saving,
                            keyboard: TextInputType.emailAddress,
                          ),
                          _field(
                            'gstNumber',
                            'GST number',
                            Icons.receipt_long_outlined,
                            saving,
                          ),
                          _field('city', 'City', Icons.location_city, saving),
                          _field('state', 'State', Icons.map_outlined, saving),
                          _field(
                            'country',
                            'Country',
                            Icons.public_outlined,
                            saving,
                          ),
                          _field(
                            'postalCode',
                            'Postal code',
                            Icons.markunread_mailbox_outlined,
                            saving,
                            keyboard: TextInputType.number,
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    if (widget.controller.accessError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.controller.accessError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(saving ? 'Saving…' : 'Save and continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    IconData icon,
    bool saving, {
    int maxLines = 1,
    TextInputType? keyboard,
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 16),
    child: TextFormField(
      controller: _fields[key],
      enabled: !saving,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: _required,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  String _label(BusinessType type) => switch (type) {
    BusinessType.soleProprietorship => 'Sole proprietorship',
    BusinessType.partnership => 'Partnership',
    BusinessType.corporation => 'Corporation',
    BusinessType.llc => 'LLC',
    BusinessType.cooperative => 'Cooperative',
    BusinessType.nonprofit => 'Nonprofit',
    BusinessType.none => 'Select business type',
  };
}
