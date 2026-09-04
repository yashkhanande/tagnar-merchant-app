import 'merchant.dart';

class OnboardingDetails {
  final String businessName;
  final String businessAddress;
  final BusinessType businessType;
  final String businessPhone;
  final String businessEmail;
  final String gstNumber;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  const OnboardingDetails({
    this.businessName = '',
    this.businessAddress = '',
    this.businessType = BusinessType.none,
    this.businessPhone = '',
    this.businessEmail = '',
    this.gstNumber = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
  });

  factory OnboardingDetails.fromMap(Map<String, dynamic> data) {
    String read(String key) {
      final value = data[key];
      return value is String ? value : '';
    }

    return OnboardingDetails(
      businessName: read('businessName'),
      businessAddress: read('businessAddress'),
      businessType: BusinessType.values.firstWhere(
        (type) => type.name == read('businessType'),
        orElse: () => BusinessType.none,
      ),
      businessPhone: read('businessPhone'),
      businessEmail: read('businessEmail'),
      gstNumber: read('gstNumber'),
      city: read('city'),
      state: read('state'),
      country: read('country'),
      postalCode: read('postalCode'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName.trim(),
      'businessAddress': businessAddress.trim(),
      'businessType': businessType.name,
      'businessPhone': businessPhone.trim(),
      'businessEmail': businessEmail.trim(),
      'gstNumber': gstNumber.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'postalCode': postalCode.trim(),
      'onboardingCompleted': true,
    };
  }
}
