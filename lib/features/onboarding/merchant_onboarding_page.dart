import 'package:country_state_city/country_state_city.dart' as csc;
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
  List<csc.Country> _countries = const [];
  List<csc.State> _states = const [];
  List<csc.City> _cities = const [];
  String? _country;
  String? _state;
  String? _city;
  bool _loadingCountries = true;
  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _locationError;
  int _locationRequest = 0;

  @override
  void initState() {
    super.initState();
    final details = widget.controller.onboardingDetails;
    final identity = widget.controller.identity!;
    _businessType = details.businessType;
    _country = details.country.isEmpty ? null : details.country;
    _state = details.state.isEmpty ? null : details.state;
    _city = details.city.isEmpty ? null : details.city;
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
      'postalCode': TextEditingController(text: details.postalCode),
    };
    _loadLocations();
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

  String? _optionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address or leave it blank.';
    }
    return null;
  }

  T? _byName<T>(List<T> values, String? name, String Function(T) readName) {
    if (name == null) return null;
    final normalized = name.trim().toLowerCase();
    for (final value in values) {
      if (readName(value).toLowerCase() == normalized) return value;
    }
    return null;
  }

  Future<void> _loadLocations() async {
    final request = ++_locationRequest;
    setState(() {
      _loadingCountries = true;
      _locationError = null;
    });
    try {
      final countries = await csc.getAllCountries();
      if (!mounted || request != _locationRequest) return;
      final selectedCountry = _byName(
        countries,
        _country,
        (country) => country.name,
      );
      var states = <csc.State>[];
      var cities = <csc.City>[];
      csc.State? selectedState;
      if (selectedCountry != null) {
        states = await csc.getStatesOfCountry(selectedCountry.isoCode);
        selectedState = _byName(states, _state, (state) => state.name);
        if (selectedState != null) {
          cities = await csc.getStateCities(
            selectedCountry.isoCode,
            selectedState.isoCode,
          );
        }
      }
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _countries = countries;
        _states = states;
        _cities = cities;
        _country = selectedCountry?.name;
        _state = selectedState?.name;
        _city = _byName(cities, _city, (city) => city.name)?.name;
        _loadingCountries = false;
      });
    } catch (_) {
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _loadingCountries = false;
        _locationError = 'Could not load countries, states and cities.';
      });
    }
  }

  Future<void> _selectCountry(String? name) async {
    final request = ++_locationRequest;
    final country = _byName(_countries, name, (country) => country.name);
    setState(() {
      _country = country?.name;
      _state = null;
      _city = null;
      _states = const [];
      _cities = const [];
      _loadingStates = country != null;
      _loadingCities = false;
      _locationError = null;
    });
    if (country == null) return;
    try {
      final states = await csc.getStatesOfCountry(country.isoCode);
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _loadingStates = false;
        _locationError = 'Could not load states for ${country.name}.';
      });
    }
  }

  Future<void> _selectState(String? name) async {
    final request = ++_locationRequest;
    final country = _byName(_countries, _country, (country) => country.name);
    final state = _byName(_states, name, (state) => state.name);
    setState(() {
      _state = state?.name;
      _city = null;
      _cities = const [];
      _loadingCities = country != null && state != null;
      _locationError = null;
    });
    if (country == null || state == null) return;
    try {
      final cities = await csc.getStateCities(country.isoCode, state.isoCode);
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _loadingCities = false;
        _locationError = 'Could not load cities for ${state.name}.';
      });
    }
  }

  void _selectCity(String? name) {
    final city = _byName(_cities, name, (city) => city.name);
    setState(() => _city = city?.name);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _businessType == BusinessType.none ||
        _country == null ||
        _state == null ||
        _city == null) {
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
        city: _city!,
        state: _state!,
        country: _country!,
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
                            'Business email (optional)',
                            Icons.email_outlined,
                            saving,
                            keyboard: TextInputType.emailAddress,
                            validator: _optionalEmail,
                          ),
                          _field(
                            'gstNumber',
                            'GST number',
                            Icons.receipt_long_outlined,
                            saving,
                          ),
                          _locationDropdown(
                            'Country',
                            Icons.public_outlined,
                            _country,
                            _countries.map((country) => country.name).toList(),
                            saving || _loadingCountries,
                            _selectCountry,
                            helperText: _loadingCountries
                                ? 'Loading countries…'
                                : null,
                          ),
                          _locationDropdown(
                            'State',
                            Icons.map_outlined,
                            _state,
                            _states.map((state) => state.name).toList(),
                            saving || _country == null || _loadingStates,
                            _selectState,
                            helperText: _country == null
                                ? 'Select a country first'
                                : _loadingStates
                                ? 'Loading states…'
                                : null,
                          ),
                          _locationDropdown(
                            'City',
                            Icons.location_city,
                            _city,
                            _cities.map((city) => city.name).toList(),
                            saving || _state == null || _loadingCities,
                            _selectCity,
                            helperText: _state == null
                                ? 'Select a state first'
                                : _loadingCities
                                ? 'Loading cities…'
                                : null,
                          ),
                          if (_locationError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _locationError!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: saving ? null : _loadLocations,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
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
                      onPressed:
                          saving ||
                              _loadingCountries ||
                              _loadingStates ||
                              _loadingCities
                          ? null
                          : _save,
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
    FormFieldValidator<String>? validator,
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 16),
    child: TextFormField(
      controller: _fields[key],
      enabled: !saving,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator ?? _required,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _locationDropdown(
    String label,
    IconData icon,
    String? value,
    List<String> values,
    bool disabled,
    ValueChanged<String?> onChanged, {
    String? helperText,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value:${values.length}'),
      initialValue: values.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: disabled ? null : onChanged,
      validator: _required,
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
