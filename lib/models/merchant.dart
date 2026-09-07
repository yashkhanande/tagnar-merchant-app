import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessType {
  none,
  soleProprietorship,
  partnership,
  corporation,
  llc,
  cooperative,
  nonprofit,
}

class Merchant {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;

  final DateTime? createdAt;
  final DateTime? lastLogin;

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

  final bool onboardingCompleted;

  Merchant({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    required this.businessName,
    required this.businessAddress,
    required this.businessType,
    required this.businessPhone,
    required this.businessEmail,
    required this.gstNumber,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.onboardingCompleted,
  });

  factory Merchant.fromMap(Map<String, dynamic> data) {
    return Merchant(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',

      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),

      businessName: data['businessName'] ?? '',
      businessAddress: data['businessAddress'] ?? '',

      businessType: BusinessType.values.firstWhere(
        (type) => type.name == data['businessType'],
        orElse: () => BusinessType.none,
      ),

      businessPhone: data['businessPhone'] ?? '',
      businessEmail: data['businessEmail'] ?? '',
      gstNumber: data['gstNumber'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      country: data['country'] ?? '',
      postalCode: data['postalCode'] ?? '',

      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,

      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),

      'lastLogin': lastLogin != null
          ? Timestamp.fromDate(lastLogin!)
          : FieldValue.serverTimestamp(),

      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessType': businessType.name,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'gstNumber': gstNumber,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,

      'onboardingCompleted': onboardingCompleted,
    };
  }
}
