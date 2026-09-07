import '../auth/auth_repository.dart';

class MerchantShop {
  const MerchantShop({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    this.anchorId,
  });
  final String id, name, address, status;
  final String? anchorId;
  bool get approved =>
      status == 'approved' && anchorId != null && anchorId!.isNotEmpty;
  factory MerchantShop.fromMap(String id, Map<String, dynamic> data) =>
      MerchantShop(
        id: id,
        name: data['name'] as String? ?? '',
        address: data['address'] as String? ?? '',
        status: data['status'] as String? ?? 'pending',
        anchorId: data['anchorId'] as String?,
      );
}

class ShopAccessSnapshot {
  const ShopAccessSnapshot(this.shops, {required this.serverConfirmed});
  final List<MerchantShop> shops;
  final bool serverConfirmed;
}

class ApprovedAnchor {
  const ApprovedAnchor({
    required this.id,
    required this.shopId,
    required this.merchantId,
  });
  final String id, shopId, merchantId;
}

abstract interface class MerchantAccessRepository {
  Future<void> ensureProfile(MerchantIdentity identity);
  Stream<ShopAccessSnapshot> watchShops(String uid);
  Stream<ApprovedAnchor?> watchApprovedAnchor({
    required String uid,
    required MerchantShop shop,
  });
}

class AccessFailure implements Exception {
  const AccessFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
