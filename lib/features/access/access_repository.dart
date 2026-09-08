import '../auth/auth_repository.dart';
import '../../models/onboarding_details.dart';

class MerchantProfile {
  const MerchantProfile({
    required this.onboardingCompleted,
    required this.details,
  });
  final bool onboardingCompleted;
  final OnboardingDetails details;
}

class MerchantAnchor {
  const MerchantAnchor({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.views = 0,
    this.gamePlayed = 0,
  });
  final String id, name;
  final double? latitude, longitude;
  final int views, gamePlayed;
  String get displayId => id;
  String get location => latitude == null || longitude == null
      ? 'Location not provided'
      : '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  factory MerchantAnchor.fromMap(String id, Map<String, dynamic> data) {
    int count(String field) {
      final value = data[field];
      return value is num && value >= 0 ? value.toInt() : 0;
    }

    return MerchantAnchor(
      id: id,
      name: (data['prefabName'] as String?)?.trim().isNotEmpty == true
          ? data['prefabName'] as String
          : 'Anchor ${id.substring(0, id.length < 8 ? id.length : 8)}',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      views: count('views'),
      gamePlayed: count('gamePlayed'),
    );
  }
}

class AnchorAccessSnapshot {
  const AnchorAccessSnapshot(this.anchors, {required this.serverConfirmed});
  final List<MerchantAnchor> anchors;
  final bool serverConfirmed;
}

abstract interface class MerchantAccessRepository {
  Future<MerchantProfile> ensureProfile(MerchantIdentity identity);
  Future<void> saveOnboarding(String uid, OnboardingDetails details);
  Stream<AnchorAccessSnapshot> watchAnchors(String uid);
}

class AccessFailure implements Exception {
  const AccessFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
